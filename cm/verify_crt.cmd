@set certFile=%1
@if defined certFile openssl verify -CAfile P:\AC\AC_Tree\SG_UniPass_AC_tree.crt %certFile%
