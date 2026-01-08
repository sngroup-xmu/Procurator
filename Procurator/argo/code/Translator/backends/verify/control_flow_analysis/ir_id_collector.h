//
// Created by smy on 2025/1/3.
//

#ifndef IR_ID_COLLECTOR_H
#define IR_ID_COLLECTOR_H
#include <unordered_set>
#include "ir/ir.h"           // 这会包含 ir-inline.h，需要Inspector等完整

class IrIdCollector: public Inspector {
    std::unordered_set<int> nodeIds;  // 用于记录收集到的 ID

public:
    // 重载 preorder 或 postorder
    bool preorder(const IR::Node *node) override;
    std::unordered_set<int> getChildrenIds()  { return nodeIds; }
};

#endif //IR_ID_COLLECTOR_H
