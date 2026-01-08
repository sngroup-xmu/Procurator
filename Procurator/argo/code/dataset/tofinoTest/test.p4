/************************************************************
 * Example Tofino P4 code (TNA/T2NA style) demonstrating:
 *   - Parser (Ethernet + partial message parsing)
 *   - Ingress with multiple registers + table
 *   - Recirculate by setting a special egress port
 *   - Egress pipeline simplified (bypass)
 *   - Pipeline(...) + Switch(...) structure
 *
 * NOTE:
 *   - Some macros/symbols (like PORT_METADATA_SIZE, Tofino metadata)
 *     are placeholders or simplified. Adjust them for real environment.
 *   - This code is primarily for demonstration and generating IR JSON.
 ************************************************************/

#include <core.p4>

#if __TARGET_TOFINO__ == 2
    #include <t2na.p4>     // Tofino 2
#else
    #include <tna.p4>      // Tofino 1
#endif

/****************************************************************************/
/* 1) HEADERS                                                               */
/****************************************************************************/

typedef bit<48> mac_addr_t;
typedef bit<16> ether_type_t;

// Ethernet header
header ethernet_t {
    mac_addr_t   dst_addr;
    mac_addr_t   src_addr;
    ether_type_t ether_type;
}

// 枚举示例 (message type)
enum bit<32> MsgType_t {
    TUPLE_GET_REQ  = 0x01000000,
    TUPLE_GET_RES  = 0x02000000,
    TUPLE_PUT_REQ  = 0x03000000,
    TUPLE_PUT_RES  = 0x04000000
}

// 发送者、消息ID
typedef bit<32> node_t;
typedef bit<64> msgid_t;

header msg_t {
    bit<16>    padding;  // 占位用
    MsgType_t  type;
    node_t     sender;
    msgid_t    msg_id;
}

// 访问模式
enum bit<8> AccessMode_t {
    INVALID = 0x00,
    READ    = 0x01,
    WRITE   = 0x02
}

// TUPE 请求头
header tuple_msg_t {
    bit<64>     ts;
    bit<64>     tid;
    bit<64>     rid;
    AccessMode_t mode;
    bit<8>      by_switch;
    bit<16>     lock_idx;
}

// Optional data
header tuple_t {
    bit<32> field_0;
    bit<32> field_1;
    bit<32> field_2;
}

struct header_t {
    ethernet_t  ethernet;
    msg_t       msg;
    tuple_msg_t tuple_get_req;
    tuple_msg_t tuple_put_req;
    tuple_t     data;
}

struct metadata_t {
    /* 你的自定义 metadata, 如果需要可在此添加 */
}

control BypassEgress(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    action set_bypass_egress() {
        ig_tm_md.bypass_egress = 1w1;
    }

    table bypass_egress {
        actions = {
            set_bypass_egress;
        }
        const default_action = set_bypass_egress;
        size = 1;
    }

    apply {
        bypass_egress.apply();
    }
}

/****************************************************************************/
/* 3) PARSER for Ingress                                                    */
/****************************************************************************/

parser TofinoIngressParser(
    packet_in                         pkt,
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }
    state parse_resubmit {
        transition reject; // or do something if needed
    }
    state parse_port_metadata {
        // skip a few bytes if needed
        // e.g. pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

parser IngressParser(
    packet_in                                      pkt,
    out header_t                                   hdr,
    out metadata_t                                 ig_md,
    out ingress_intrinsic_metadata_t               ig_intr_md)
{
    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x1000: parse_msg;
            default: accept;
        }
    }

    state parse_msg {
        pkt.extract(hdr.msg);
        transition select(hdr.msg.type) {
            MsgType_t.TUPLE_GET_REQ: parse_tuple_get_req;
            MsgType_t.TUPLE_PUT_REQ: parse_tuple_put_req;
            default: accept;
        }
    }

    state parse_tuple_get_req {
        pkt.extract(hdr.tuple_get_req);
        transition accept;
    }

    state parse_tuple_put_req {
        pkt.extract(hdr.tuple_put_req);
        transition select(hdr.tuple_put_req.mode) {
            AccessMode_t.WRITE: parse_data;
            default: accept;
        }
    }

    state parse_data {
        pkt.extract(hdr.data);
        transition accept;
    }
}

control IngressDeparser(
    packet_out                                        pkt,
    inout header_t                                    hdr,
    in    metadata_t                                  ig_md,
    in    ingress_intrinsic_metadata_for_deparser_t   ig_intr_dprsr_md)
{
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.msg);
        pkt.emit(hdr.tuple_get_req);
        pkt.emit(hdr.tuple_put_req);
        pkt.emit(hdr.data);
    }
}

/****************************************************************************/
/* 4) Egress Parser + Egress (简化空实现)                                   */
/****************************************************************************/
parser EmptyEgressParser(
    packet_in                              pkt,
    out header_t                     hdr,
    out metadata_t                   eg_md,
    out egress_intrinsic_metadata_t        eg_intr_md)
{
    state start {
        // 这里若有需要可 extract(eg_intr_md)
        transition accept;
    }
}

control EmptyEgress(
    inout header_t                              hdr,
    inout metadata_t                            eg_md,
    in    egress_intrinsic_metadata_t                 eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t    eg_intr_dprs_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    apply {
        BypassEgress bypass();
        bypass.apply();
    }
}

control EmptyEgressDeparser(
    packet_out                                         pkt,
    inout header_t                               hdr,
    in metadata_t                                eg_md,
    in egress_intrinsic_metadata_for_deparser_t        ig_intr_dprs_md)
{
    apply {
        // do nothing
    }
}

/****************************************************************************/
/* 5) INGRESS CONTROL                                                       */
/****************************************************************************/
control Ingress(
    inout header_t                                    hdr,
    inout metadata_t                                  ig_md,
    in    ingress_intrinsic_metadata_t                ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t    ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t   ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t         ig_tm_md)
{
    /********************************************************/
    /* Actions                                             */
    /********************************************************/
    action swap_mac() {
        mac_addr_t old_mac = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = hdr.ethernet.src_addr;
        hdr.ethernet.src_addr = old_mac;
    }

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    // Recirculate: 以 196(示例) 为循环端口
    action recirculate_pkt() {
        ig_tm_md.ucast_egress_port = 9w196;
    }

    /********************************************************/
    /* Tables                                              */
    /********************************************************/
    table l2fwd {
        key = {
            hdr.ethernet.dst_addr : exact;
        }
        actions = {
            send;
            @defaultonly drop;
        }
        size = 256;
        const default_action = drop;
    }

    /********************************************************/
    /* Registers + RegisterActions                         */
    /* (示例: locks, data_0/1/2)                           */
    /********************************************************/
    Register<bit<32>, bit<16>>(16384, 0x0) locks;
    RegisterAction<bit<32>, bit<16>, bit<8>>(locks) try_lock_exclusive = {
        void apply(inout bit<32> value, out bit<8> granted) {
            if (value == 0) {
                value = 0x7fffffff;  // exclusive locked
                granted = 1;
            } else {
                granted = 0;
            }
        }
    };
    RegisterAction<bit<32>, bit<16>, bit<8>>(locks) unlock = {
        void apply(inout bit<32> value, out bit<8> ok) {
            if (value == 0x7fffffff) {
                value = 0;
            } else if (value > 0) {
                value = value - 1;
            }
            ok = 1;
        }
    };

    Register<bit<32>, bit<16>>(16384, 0x0) data_0;
    RegisterAction<bit<32>, bit<16>, bit<32>>(data_0) read_0 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = value;
        }
    };
    RegisterAction<bit<32>, bit<16>, bit<32>>(data_0) write_0 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            // 将 hdr.data.field_0 写入 register
            value = hdr.data.field_0;
            rv = value;
        }
    };

    /********************************************************/
    /* main apply logic                                    */
    /********************************************************/
    apply {
        // 1) 如果 msg.type == TUPLE_GET_REQ 并且 tuple_get_req合法
        if (hdr.tuple_get_req.isValid() && hdr.msg.type == MsgType_t.TUPLE_GET_REQ) {
            bit<8> granted;
            granted = try_lock_exclusive.execute(hdr.tuple_get_req.lock_idx);
            if (granted == 1) {
                // read register
                bit<32> r0 = read_0.execute(hdr.tuple_get_req.lock_idx);
                hdr.data.setValid();
                hdr.data.field_0 = r0;
                // hack: set other fields if needed
            } else {
                // lock failed => do nothing or mark
            }
            // reply
            swap_mac();
            hdr.msg.type = MsgType_t.TUPLE_GET_RES;
        }
        // 2) 如果是 TUPLE_PUT_REQ
        else if (hdr.tuple_put_req.isValid() && hdr.msg.type == MsgType_t.TUPLE_PUT_REQ) {
            // write
            bit<32> dummy_rv;
            dummy_rv = write_0.execute(hdr.tuple_put_req.lock_idx);
            // unlock
            bit<8> ok = unlock.execute(hdr.tuple_put_req.lock_idx);

            swap_mac();
            hdr.msg.type = dummy_rv;
            hdr.msg.type = MsgType_t.TUPLE_PUT_RES;
        }

        // 3) 演示 recirculate：简单判断
        if (hdr.ethernet.src_addr[32:16] == 0x1234) {
            recirculate_pkt();
        }

        // 4) Table lookup
        l2fwd.apply();

        // 5) 其他
        ig_tm_md.bypass_egress = 1w1;  // 配合 BypassEgress
    }
}


Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EmptyEgressParser(),
    EmptyEgress(),
    EmptyEgressDeparser()
) pipe;

Switch(pipe) main;
