#ifndef __ODB_P4_H__
#define __ODB_P4_H__

/****************************************************
 * intrinsic_metadata_t
 * P4 intrinsic metadata (mandatory)
 ****************************************************/
header_type p4db_intrinsic_metadata_t {
	fields {
        ingress_global_timestamp : 48;
        lf_field_list : 8;
        mcast_grp : 16;
        egress_rid : 16;
        resubmit_flag : 8;
        recirculate_flag : 8;
        degist_receiver0 : 8;
        degist_receiver1 : 8;
        degist_receiver2 : 8;
        degist_receiver3 : 8;
        degist_receiver4 : 8;
        degist_receiver5 : 8;
        degist_receiver6 : 8;
        degist_receiver7 : 8;
        degist_receiver8 : 8;
        degist_receiver9 : 8;
	}
}

metadata p4db_intrinsic_metadata_t p4db_intrinsic_metadata;

header_type odb_metadata_t {
    fields {
        match_result : 32;
        damper           : 16;
        damper_threshold : 16;
        action_id : 16;
        action_parameter1 : 64;
        action_parameter2 : 64;
        action_parameter3 : 64;
        action_parameter4 : 64;
    }
}

metadata odb_metadata_t odb_metadata;


#define ACTION_WITHOUT_PARAM(A, ID)             \
action act_##A() {                            \
    A();                                        \
    modify_field(odb_metadata.action_id, ID);   \
}                                           


#define ACTION_WITH_1_PARAM(A, ID, P1)          \
action act_##A(P1) {                       \
    A(P1);                                      \
    modify_field(odb_metadata.action_id, ID);   \
    modify_field(odb_metadata.action_parameter1, P1); \
}                                             


#define ACTION_WITH_2_PARAM(A, ID, P1, P2)          \
action act_##A(P1, P2) {                            \
    A(P1, P2);                                      \
    modify_field(odb_metadata.action_id, ID);   \
    modify_field(odb_metadata.action_parameter1, P1); \
    modify_field(odb_metadata.action_parameter2, P2); \
}                                           


#define ACT(A) act_##A


action set_match_result(r) {
    modify_field(odb_metadata.match_result, r);
}

action gen_watch(id) {
#ifndef WATCH_LIST 
    no_op();
#else 
    generate_digest(id, WATCH_LIST);
#endif
}

action gen_predication(id) {
#ifndef PREDICATION_LIST 
    no_op();
#else 
    generate_digest(id, PREDICATION_LIST);
#endif
}

action gen_break(id) {
#ifndef BREAK_LIST 
    no_op();
#else 
    generate_digest(id, BREAK_LIST);
#endif
}

action gen_match(id) {
#ifndef MATCH_LIST 
    no_op();
#else 
    generate_digest(id, MATCH_LIST);
#endif
}

action gen_action(id) {
#ifndef ACTION_LIST 
    no_op();
#else 
    generate_digest(id, ACTION_LIST);
#endif
}


action set_damper(index, threshold) {
    register_read(odb_metadata.damper, damper_register, index);
    register_write(damper_register, index, odb_metadata.damper + 1);
    modify_field(odb_metadata.damper_threshold, threshold);
}

action clear_damper(index) {
    register_write(damper_register, index, 0);
}


#define DAMPER_CONTROL(X, S)       \
table damper_tbl_##X {  \
    actions {           \
        set_damper;     \
    }                   \
}                       \
table damper_end_tbl_##X {  \
    actions {               \
        clear_damper;       \
    }                       \
}                           \
control damper_##X {            \
    apply(damper_tbl_##X);        \
    if (odb_metadata.damper >= odb_metadata.damper_threshold) { \
        apply(S);                               \
        apply(damper_end_tbl_##X);  \
    }   \
}   

#define DAMPER(X) damper_##X()


register damper_register {
    width: 16;
    instance_count: 1024;
}



#endif