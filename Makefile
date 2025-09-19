PACKAGES = str,num

DIR_GUARD = @mkdir -p $(@D)

EX_NAME = dBPL

SOURCE_DIR=src
# LOGIC_SOURCE_DIR=src/logic

BIN_DIR=bin
# LOGIC_BIN_DIR=bin/logic
OBJ_DIR=${SOURCE_DIR}
# LOGIC_OBJ_DIR=${LOGIC_SOURCE_DIR}

# OCAMLC_FLAGS=-bin-annot -w -26  -I $(OBJ_DIR) -I $(LOGIC_OBJ_DIR)
# OCAMLOPT_FLAGS=-bin-annot -w -26 -I $(RELEASE_DIR) -I $(LOGIC_RELEASE_DIR)
# OCAMLDEP_FLAGS=-I $(SOURCE_DIR) -I $(LOGIC_SOURCE_DIR)

OCAMLC_FLAGS=-bin-annot -w -26  -I $(OBJ_DIR)
OCAMLOPT_FLAGS=-bin-annot -w -26 -I $(RELEASE_DIR)
OCAMLDEP_FLAGS=-I $(SOURCE_DIR)

MAIN_FILE=main
# LOGIC_FILES=\
#     lib intro formulas prop fol skolem fol_ex\

# LOGIC_FILES_WITH_MLI=\
#     lib intro formulas prop fol skolem fol_ex\

# TOP_FILES = expr utils rule_preprocess stratification derivation parser lexer generator ast2fol ast2theorem verifier fuser 

TOP_FILES = expr utils parser lexer


TOP_FILES_WITH_MLI=\
	parser

FILES=\
#     $(LOGIC_FILES:%=logic/%)\
    $(TOP_FILES) \

.PHONY: all clean
all: $(BIN_DIR)/$(EX_NAME)

$(SOURCE_DIR)/parser.ml $(SOURCE_DIR)/parser.mli: $(SOURCE_DIR)/parser.mly
	ocamlyacc $<
$(SOURCE_DIR)/lexer.ml:	$(SOURCE_DIR)/lexer.mll
	ocamllex $<

$(BIN_DIR)/$(EX_NAME): $(FILES:%=$(OBJ_DIR)/%.cmo) $(OBJ_DIR)/$(MAIN_FILE).cmo
	$(DIR_GUARD)
	ocamlfind ocamlc $(OCAMLC_FLAGS) -package $(PACKAGES) -thread -linkpkg $(FILES:%=$(OBJ_DIR)/%.cmo) $(OBJ_DIR)/$(MAIN_FILE).cmo -o $(BIN_DIR)/$(EX_NAME)

$(TOP_FILES_WITH_MLI:%=$(OBJ_DIR)/%.cmi): $(OBJ_DIR)/%.cmi: $(SOURCE_DIR)/%.mli
	$(DIR_GUARD)
	ocamlfind ocamlc $(OCAMLC_FLAGS) -o $(OBJ_DIR)/$* -c $<

$(TOP_FILES_WITH_MLI:%=$(OBJ_DIR)/%.cmo): $(OBJ_DIR)/%.cmo: $(SOURCE_DIR)/%.ml $(OBJ_DIR)/%.cmi
	$(DIR_GUARD)
	ocamlfind ocamlc $(OCAMLC_FLAGS) -package $(PACKAGES) -thread -o $(OBJ_DIR)/$* -c $<

# $(LOGIC_FILES_WITH_MLI:%=$(LOGIC_OBJ_DIR)/%.cmi): $(LOGIC_OBJ_DIR)/%.cmi: $(LOGIC_SOURCE_DIR)/%.mli
# 	$(DIR_GUARD)
# 	ocamlfind ocamlc $(OCAMLC_FLAGS) -o $(LOGIC_OBJ_DIR)/$* -c $<

# $(LOGIC_FILES_WITH_MLI:%=$(LOGIC_OBJ_DIR)/%.cmo): $(LOGIC_OBJ_DIR)/%.cmo: $(LOGIC_SOURCE_DIR)/%.ml $(LOGIC_OBJ_DIR)/%.cmi
# 	$(DIR_GUARD)
# 	ocamlfind ocamlc $(OCAMLC_FLAGS) -package $(PACKAGES) -thread -o $(LOGIC_OBJ_DIR)/$* -c $<

# $(OBJ_DIR)/%.cmi $(OBJ_DIR)/%.cmo $(OBJ_DIR)/%.cmt: $(SOURCE_DIR)/%.ml
# 	$(DIR_GUARD)
# 	ocamlfind ocamlc $(OCAMLC_FLAGS) -package $(PACKAGES) -thread -o $(OBJ_DIR)/$* -c $<

include depend

# clean:
# 	rm -r -f $(BIN_DIR)/* $(SOURCE_DIR)/parser.mli $(SOURCE_DIR)/parser.ml $(SOURCE_DIR)/lexer.ml $(OBJ_DIR)/*.cmt $(LOGIC_OBJ_DIR)/*.cmt $(OBJ_DIR)/*.cmti $(LOGIC_OBJ_DIR)/*.cmti $(OBJ_DIR)/*.cmo $(LOGIC_OBJ_DIR)/*.cmo $(OBJ_DIR)/*.cmi $(LOGIC_OBJ_DIR)/*.cmi

clean:
	rm -r -f $(BIN_DIR)/* $(SOURCE_DIR)/parser.mli $(SOURCE_DIR)/parser.ml $(SOURCE_DIR)/lexer.ml $(OBJ_DIR)/*.cmt $(OBJ_DIR)/*.cmti $(OBJ_DIR)/*.cmo $(OBJ_DIR)/*.cmi