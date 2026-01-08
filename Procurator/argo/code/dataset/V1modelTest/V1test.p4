#include <core.p4>
#include <v1model.p4>

// 一些示例化的 header
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct metadata_t {
    // 为了示例，这里放一些控制状态的元数据。
    bit<8>  my_condition;
    bit<16> egress_port;
    bool    doRecirculate;
    bool    doResubmit;
    bool    doMirror;
}

// 标准 v1model 定义


/* 解析后存放的 header */
header ethernet_t    eth;

/* 元数据 */
metadata_t           meta;

/* 标准 v1model 元数据 */
standard_metadata_t standard_metadata;

) main {

    // 解析 (Parser)
    action parseHeaders() {
        // ...
    }
    parser MyParser(packet_in packet,
                    out headers hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t sm) {
        state start {
            // 仅做示例，不做完整解析
            transition accept;
        }
    }

    // 控制逻辑 (Ingress)
    action doSetRecirculate() {
        meta.doRecirculate = true;
    }
    action doSetResubmit() {
        meta.doResubmit = true;
    }
    action doSetMirror() {
        meta.doMirror = true;
    }
    action doNothing() {
        // no-op
    }

    table t_control {
        actions = {
            doSetRecirculate;
            doSetResubmit;
            doSetMirror;
            doNothing;
        }
        size = 1024;
        default_action = doNothing;
    }

    control Ingress(inout headers hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t sm) {
        apply {
            // 根据某些匹配条件决定要不要 recirculate / resubmit / mirror
            t_control.apply();
        }
    }

    // Egress 逻辑
    control Egress(inout headers hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t sm) {
        apply {
            // 在 v1model 里原本可以直接调用 recirculate(...) / resubmit(...) / mirror(...)
            // 这里只做示例，先“标记”一下，在结尾统一处理
        }
    }

    // Deparser
    control MyDeparser(packet_out packet,
                       in headers hdr) {
        apply {
            // ...
        }
    }

    // v1model 中最原始的做法是 pipeline 里直接调用 recirculate() / resubmit() 等，
    // 但这里为了你的 Spin 翻译需求，先在 ingress/egress 阶段设置标记 doRecirculate/doResubmit/doMirror
    // 最后再统一收敛处理。
    // 也可以把 recirculate 等放进 egress control 里直接调用。
    // 下面给出一个稍带调用的做法：
    control MyVerifyChecksum(inout headers hdr, inout metadata_t meta) { apply {} }
    control MyComputeChecksum(inout headers hdr, inout metadata_t meta) { apply {} }

    // V1Switch 结构
    MyParser()           p;
    MyVerifyChecksum()   vc;
    Ingress()            ig;
    Egress()             eg;
    MyComputeChecksum()  cc;
    MyDeparser()         dp;

    // v1model 的管线连接
  V1Switch()(  p(parser);
    vc();
    ig();
    eg();
    cc();
    dp(deparser);
}
