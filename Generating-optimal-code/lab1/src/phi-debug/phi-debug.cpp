#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <gcc-plugin.h>
#include <plugin-version.h>
#include <coretypes.h>
#include <tree.h>
#include <tree-pass.h>
#include <context.h>
#include <basic-block.h>
#include <gimple.h>
#include <gimple-iterator.h>
#include <function.h>

int plugin_is_GPL_compatible = 1;

static void print_basic_block_info(basic_block bb)
{
    edge e;
    edge_iterator ei;

    printf("Basic block %d:\n", bb->index);

    printf("Predecessors: { ");
    FOR_EACH_EDGE(e, ei, bb->preds)
    printf("%d ", e->src->index);
    printf("}\n");

    printf("Successors: { ");
    FOR_EACH_EDGE(e, ei, bb->succs)
    printf("%d ", e->dest->index);
    printf("}\n");
}

static void print_tree_expr(tree t)
{
    if (!t)
    {
        printf("NULL");
        return;
    }

    switch (TREE_CODE(t))
    {
    case SSA_NAME:
    {
        tree var = SSA_NAME_VAR(t);
        if (var && DECL_NAME(var))
        {
            printf("%s_%d",
                   IDENTIFIER_POINTER(DECL_NAME(var)),
                   SSA_NAME_VERSION(t));
        }
        else
        {
            printf("_%d", SSA_NAME_VERSION(t));
        }
        break;
    }

    case INTEGER_CST:
        printf("%ld", TREE_INT_CST_LOW(t));
        break;

    case VAR_DECL:
    case PARM_DECL:
        printf("%s", IDENTIFIER_POINTER(DECL_NAME(t)));
        break;

    case ARRAY_REF:
        print_tree_expr(TREE_OPERAND(t, 0));
        printf("[");
        print_tree_expr(TREE_OPERAND(t, 1));
        printf("]");
        break;

    case MEM_REF:
        printf("*(");
        print_tree_expr(TREE_OPERAND(t, 0));
        printf(")");
        break;

    case COMPONENT_REF:
        print_tree_expr(TREE_OPERAND(t, 0));
        printf(".");
        print_tree_expr(TREE_OPERAND(t, 1));
        break;

    case ADDR_EXPR:
        printf("&");
        print_tree_expr(TREE_OPERAND(t, 0));
        break;

    default:
        printf("expr");
    }
}

static const char *op_name(enum tree_code code)
{
    switch (code)
    {
    case PLUS_EXPR:
        return "+";
    case MINUS_EXPR:
        return "-";
    case MULT_EXPR:
        return "*";
    case TRUNC_DIV_EXPR:
        return "/";
    case LT_EXPR:
        return "<";
    case LE_EXPR:
        return "<=";
    case GT_EXPR:
        return ">";
    case GE_EXPR:
        return ">=";
    case EQ_EXPR:
        return "==";
    case NE_EXPR:
        return "!=";
    default:
        return "?";
    }
}

static void print_gimple_stmt(gimple *stmt)
{
    switch (gimple_code(stmt))
    {
    case GIMPLE_ASSIGN:
    {
        gassign *as = as_a<gassign *>(stmt);

        print_tree_expr(gimple_assign_lhs(as));
        printf(" = ");

        tree rhs1 = gimple_assign_rhs1(as);
        tree rhs2 = gimple_assign_rhs2(as);

        if (rhs2)
        {
            print_tree_expr(rhs1);
            printf(" %s ", op_name(gimple_assign_rhs_code(as)));
            print_tree_expr(rhs2);
        }
        else
        {
            print_tree_expr(rhs1);
        }
        break;
    }

    case GIMPLE_PHI:
    {
        gphi *phi = as_a<gphi *>(stmt);

        print_tree_expr(gimple_phi_result(phi));
        printf(" = PHI(");

        int n = gimple_phi_num_args(phi);
        for (int i = 0; i < n; i++)
        {
            if (i > 0)
                printf(", ");

            print_tree_expr(gimple_phi_arg_def(phi, i));
            printf("<bb%d>", gimple_phi_arg_edge(phi, i)->src->index);
        }

        printf(")");
        break;
    }

    case GIMPLE_COND:
    {
        gcond *cond = as_a<gcond *>(stmt);

        printf("if (");
        print_tree_expr(gimple_cond_lhs(cond));
        printf(" %s ", op_name(gimple_cond_code(cond)));
        print_tree_expr(gimple_cond_rhs(cond));
        printf(")");
        break;
    }

    case GIMPLE_CALL:
    {
        printf("CALL ");

        tree fn = gimple_call_fn(stmt);
        if (TREE_CODE(fn) == ADDR_EXPR)
            fn = TREE_OPERAND(fn, 0);

        if (DECL_NAME(fn))
            printf("%s", IDENTIFIER_POINTER(DECL_NAME(fn)));

        printf("(");

        int n = gimple_call_num_args(stmt);
        for (int i = 0; i < n; i++)
        {
            if (i > 0)
                printf(", ");
            print_tree_expr(gimple_call_arg(stmt, i));
        }

        printf(")");
        break;
    }

    case GIMPLE_RETURN:
    {
        printf("RETURN ");
        tree val = gimple_return_retval(as_a<greturn *>(stmt));
        if (val)
            print_tree_expr(val);
        break;
    }

    case GIMPLE_LABEL:
        printf("LABEL");
        break;

    default:
        printf("OTHER");
        break;
    }

    printf("\n");
}

static unsigned int analyze_function(function *fn)
{
    printf("\n=== Function: %s ===\n", function_name(fn));

    basic_block bb;

    FOR_EACH_BB_FN(bb, fn)
    {
        print_basic_block_info(bb);

        printf("PHI:\n");
        for (gphi_iterator gpi = gsi_start_phis(bb);
             !gsi_end_p(gpi);
             gsi_next(&gpi))
        {
            print_gimple_stmt(gsi_stmt(gpi));
        }

        printf("GIMPLE:\n");
        for (gimple_stmt_iterator gsi = gsi_start_bb(bb);
             !gsi_end_p(gsi);
             gsi_next(&gsi))
        {
            print_gimple_stmt(gsi_stmt(gsi));
        }

        printf("\n");
    }

    return 0;
}

static struct pass_data ir_pass_data =
    {
        GIMPLE_PASS,
        "ir_dump",
        OPTGROUP_NONE,
        TV_NONE,
        PROP_ssa,
        0,
        0,
        0,
        0};

struct ir_pass : gimple_opt_pass
{
    ir_pass(gcc::context *ctx)
        : gimple_opt_pass(ir_pass_data, ctx) {}

    unsigned int execute(function *fn)
    {
        return analyze_function(fn);
    }

    ir_pass *clone() { return this; }
};

int plugin_init(struct plugin_name_args *plugin_info,
                struct plugin_gcc_version *version)
{
    if (!plugin_default_version_check(version, &gcc_version))
        return 1;

    static struct register_pass_info pass_info;

    pass_info.pass = new ir_pass(g);
    pass_info.reference_pass_name = "ssa";
    pass_info.ref_pass_instance_number = 1;
    pass_info.pos_op = PASS_POS_INSERT_AFTER;

    register_callback(plugin_info->base_name,
                      PLUGIN_PASS_MANAGER_SETUP,
                      NULL,
                      &pass_info);

    return 0;
}