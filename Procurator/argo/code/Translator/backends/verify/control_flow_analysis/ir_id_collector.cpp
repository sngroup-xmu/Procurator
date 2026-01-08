//
// Created by smy on 2025/1/3.
//

#include "ir_id_collector.h"


bool IrIdCollector::preorder(const IR::Node* node) {
    nodeIds.insert(node->id);
    return true;  // 继续遍历
}