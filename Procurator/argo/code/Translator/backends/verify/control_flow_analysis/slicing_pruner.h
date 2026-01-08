#pragma once
#include "ir/ir.h"
#include "ir/visitor.h"
#include <unordered_set>
#include <iostream>

class SlicingPruner : public Transform {
public:
    explicit SlicingPruner(const std::unordered_set<int>& removeSet)
        : removeSet(removeSet)
    {
        // 允许重复访问 DAG 中同一个节点
        // 避免多个父节点共享子节点时只访问一次
        visitDagOnce = false;
    }

private:
    // 需要删除的 IR Node id 集合
    std::unordered_set<int> removeSet;
    //
    //     /**
    //  * \brief 对 P4Program 本身强制保留，仅过滤其 objects 中不在 keepIds 的部分。
    //  *        不使用 `reserve()`，不使用 `operator=`.
    //  */
    const IR::Node* preorder(IR::P4Program* prog) override {
        // prog 自身不论是否在 keepIds，都强制保留。
        // 只过滤 objects
        auto newObjs = new IR::Vector<IR::Node>();

        for (auto obj : prog->objects) {
            if (obj && removeSet.count(obj->id) > 0) {
                // 不在 keepIds，可以直接丢弃
                IrIdCollector ir_id_collector;
                obj->apply(ir_id_collector);
                for (auto id: ir_id_collector.getChildrenIds()) {
                    removeSet.insert(id);
                }
            } else {
                // 保留
                newObjs->push_back(obj);
            }
        }
        // 将新对象集赋给 program->objects
        prog->objects.clear();
        for (auto o : *newObjs) {
            prog->objects.push_back(o);
        }
        return prog; // 返回自身
    }

    /// ============ 强制保留：P4Control ============

    /**
     * \brief P4Control 本身强制保留，但其 controlLocals 过滤不在 keepIds 的声明
     */
    const IR::Node* preorder(IR::P4Control* ctrl) override {
        // 无论 ctrl 是否在 keepIds，都强制保留
        auto filteredLocals = new IR::Vector<IR::Declaration>();
        for (auto decl : ctrl->controlLocals) {
            // 如果 decl 不在 keepIds，就丢弃
            if (decl && removeSet.count(decl->id) > 0) {
                IrIdCollector ir_id_collector;
                decl->apply(ir_id_collector);
                for (auto id: ir_id_collector.getChildrenIds()) {
                    removeSet.insert(id);
                }
            } else {
                filteredLocals->push_back(decl);
            }
        }
        ctrl->controlLocals.clear();
        for (auto d : *filteredLocals) {
            ctrl->controlLocals.push_back(d);
        }
        // 继续访问 body / 等下层(Transform 会自动访问 body)
        return ctrl;
    }

    /// ============ 强制保留：BlockStatement ============

    /**
     * \brief BlockStatement 本身强制保留，但其 components 会过滤
     */
    const IR::Node* preorder(IR::BlockStatement* blk) override {
        // 无论 blk 是否在 keepIds，都强制保留
        auto newComponents = new IR::Vector<IR::StatOrDecl>();

        for (auto stmt : blk->components) {
            if (stmt && removeSet.count(stmt->id) > 0) {
                IrIdCollector ir_id_collector;
                stmt->apply(ir_id_collector);
                for (auto id: ir_id_collector.getChildrenIds()) {
                    removeSet.insert(id);
                }
            } else {
                // 过滤掉
                newComponents->push_back(stmt);
            }
        }
        blk->components.clear();
        for (auto s : *newComponents) {
            blk->components.push_back(s);
        }
        return blk;
    }

    /// ============ P4Action ============

    /**
     * \brief 如果 P4Action 不在 keepIds，则返回 nullptr
     */
    const IR::Node* preorder(IR::P4Action* action) override {
        // 如果不在 keepIds，就删
        if (removeSet.count(action->id) != 0) {
            IrIdCollector ir_id_collector;
            action->apply(ir_id_collector);
            for (auto id: ir_id_collector.getChildrenIds()) {
                removeSet.insert(id);
            }
            action->annotations = new IR::Annotations;
            action->body = new IR::BlockStatement;
            action->parameters = new IR::ParameterList;
        }
        return action;
    }

    /// ============ ParserState / 仅示例 ============

    /**
     * \brief 若 ParserState 不在 keepIds，返回nullptr
     *        否则过滤其 components
     */
    const IR::Node* preorder(IR::ParserState* state) override {
        if (removeSet.count(state->id) != 0) {
            IrIdCollector ir_id_collector;
            state->apply(ir_id_collector);
            for (auto id: ir_id_collector.getChildrenIds()) {
                removeSet.insert(id);
            }
            state->annotations = new IR::Annotations;
        }
        auto newComps = new IR::Vector<IR::StatOrDecl>();
        for (auto c : state->components) {
            if (c && removeSet.count(c->id) > 0) {
            } else {
                newComps->push_back(c);
            }
        }
        state->components.clear();
        for (auto c : *newComps) {
            state->components.push_back(c);
        }
        return state;
    }

    /// ============ P4Table / 仅示例 ============

    /**
     * \brief 如果 table 不在 keepIds，就剪掉
     *        如果要继续保留 table，也可在此过滤 properties->properties
     */
    const IR::Node* preorder(IR::P4Table* table) override {
        if (removeSet.count(table->id) != 0) {
            IrIdCollector ir_id_collector;
            table->apply(ir_id_collector);
            for (auto id: ir_id_collector.getChildrenIds()) {
                removeSet.insert(id);
            }
            table->annotations = new IR::Annotations;
            table->properties = new IR::TableProperties;
        }
        // 也可以在此对 table->properties->properties 做过滤
        return table;
    }

    /// ============ Statement / 其他 Node ============

    /**
     * \brief 如果是 Statement 且不在 keepIds 就返回 nullptr
     *        这样 BlockStatement / IfStatement 容器就会移除它
     */
    const IR::Node* preorder(IR::Statement* stmt) override {
        if (removeSet.count(stmt->id) != 0) {
            std::cout << "Remove stmt " << stmt->id << std::endl;
            IrIdCollector ir_id_collector;
            stmt->apply(ir_id_collector);
            for (auto id: ir_id_collector.getChildrenIds()) {
                removeSet.insert(id);
            }
            stmt = new IR::EmptyStatement;
        }
        return stmt;
    }

    /**
     * \brief 其余节点，如 Expression, Declaration, ...
     *        若不在 keepIds，可选择返回 nullptr, or 保留
     *        这里只是演示写法
     */
    const IR::Node* preorder(IR::Declaration* decl) override {
        // 如果要剪掉声明
        if (removeSet.count(decl->id) != 0) {
            std::cout << "Remove decl " << decl->id << std::endl;
            IrIdCollector ir_id_collector;
            decl->apply(ir_id_collector);
            for (auto id: ir_id_collector.getChildrenIds()) {
                removeSet.insert(id);
            }
            decl->name = "";
            decl->node_type_name() = "EmptyDeclaration";
        }
        return decl;
    }

    // 9) 其他节点
    //    如果不在 removeSet，就保留，否则 nullptr
    // const IR::Node* preorder(IR::Node* node) override{
    //     if (node != nullptr) {
    //         {
    //             if (removeSet.count(node->id)) {
    //                 std::cout << "Remove node " << node->id << std::endl;
    //                 return nullptr;
    //             }
    //         }
    //     }
    //     return node;
    // }
};
