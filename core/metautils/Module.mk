# Module.mk for utilities for libMeta and rootcint
# Copyright (c) 2002 Rene Brun and Fons Rademakers
#
# Author: Philippe Canal 9/1/2004

MODNAME        := metautils
MODDIR         := $(ROOT_SRCDIR)/core/$(MODNAME)
MODDIRS        := $(MODDIR)/src
MODDIRI        := $(MODDIR)/inc

METAUTILSDIR   := $(MODDIR)
METAUTILSDIRS  := $(METAUTILSDIR)/src
METAUTILSDIRI  := $(METAUTILSDIR)/inc

##### $(METAUTILSO) #####
METAUTILSH     := $(filter-out $(MODDIRI)/TMetaUtils.%,\
  $(filter-out $(MODDIRI)/LinkDef%,$(wildcard $(MODDIRI)/*.h)))
METAUTILSS     := $(filter-out $(MODDIRS)/TMetaUtils.%,\
  $(filter-out $(MODDIRS)/G__%,$(wildcard $(MODDIRS)/*.cxx)))

METAUTILSTH     += $(MODDIRI)/TMetaUtils.h
METAUTILSTS     += $(MODDIRS)/TMetaUtils.cxx
METAUTILSCXXFLAGS = $(filter-out -fno-exceptions,$(filter-out -fno-rtti,$(CLINGCXXFLAGS)))
ifneq ($(CXX:g++=),$(CXX))
METAUTILSCXXFLAGS += -Wno-shadow -Wno-unused-parameter
endif

METAUTILSO     := $(call stripsrc,$(METAUTILSS:.cxx=.o))
METAUTILSTO    := $(call stripsrc,$(METAUTILSTS:.cxx=.o))

METAUTILSL     := $(MODDIRI)/LinkDef.h
METAUTILSDS    := $(call stripsrc,$(MODDIRS)/G__MetaUtils.cxx)
METAUTILSDO    := $(METAUTILSDS:.cxx=.o)
METAUTILSDH    := $(METAUTILSDS:.cxx=.h)

METAUTILSDEP   := $(METAUTILSO:.o=.d) $(METAUTILSDO:.o=.d) $(METAUTILSTO:.o=.d)

# used in the main Makefile
ALLHDRS     += $(patsubst $(MODDIRI)/%.h,include/%.h,$(METAUTILSH) $(METAUTILSTH))

# include all dependency files
INCLUDEFILES += $(METAUTILSDEP)

#### STL dictionary (replacement for cintdlls)

STLDICTS =
STLDICTS += lib/libvectorDict.$(SOEXT)
STLDICTS += lib/liblistDict.$(SOEXT)
STLDICTS += lib/libdequeDict.$(SOEXT)
STLDICTS += lib/libmapDict.$(SOEXT)
STLDICTS += lib/libmap2Dict.$(SOEXT)
STLDICTS += lib/libsetDict.$(SOEXT)
STLDICTS += lib/libmultimapDict.$(SOEXT)
STLDICTS += lib/libmultimap2Dict.$(SOEXT)
STLDICTS += lib/libmultisetDict.$(SOEXT)
STLDICTS += lib/libcomplexDict.$(SOEXT)
ifneq ($(PLATFORM),win32)
STLDICTS += lib/libvalarrayDict.$(SOEXT)
endif

STLDICTS_SRC := $(call stripsrc,$(patsubst lib/lib%Dict.$(SOEXT),$(METAUTILSDIRS)/G__std__%.cxx,$(STLDICTS)))
STLDICTS_OBJ := $(patsubst %.cxx,%.o,$(STLDICTS_SRC))
STLDICTS_DEP := $(patsubst %.cxx,%.d,$(STLDICTS_SRC))

$(call stripsrc,$(METAUTILSDIRS)/G__std__%.cxx): $(METAUTILSDIRS)/%Linkdef.h $(ROOTCINTTMPDEP)
	$(ROOTCINTTMP) -f $@ -c $(subst multi,,${*:2=}) \
	   $(ROOT_SRCDIR)/core/metautils/src/$*Linkdef.h

$(STLDICTS): lib/lib%Dict.$(SOEXT): $(call stripsrc,$(METAUTILSDIRS)/G__std__%.o) $(ORDER_) $(MAINLIBS)
	@$(MAKELIB) $(PLATFORM) $(LD) "$(LDFLAGS)" "$(SOFLAGS)" $(notdir $@) $@ "$(filter-out $(MAINLIBS),$^)" ""

lib/lib%Dict.rootmap: $(RLIBMAP) $(MAKEFILEDEP) $(METAUTILSDIRS)/%Linkdef.h
	$(RLIBMAP) -o $@ -l lib$*Dict.$(SOEXT) -c $(METAUTILSDIRS)/$*Linkdef.h

METAUTILSDEP   += $(STLDICTS_DEP)

STLDICTSMAPS = $(STLDICTS:.$(SOEXT)=.rootmap)

.PRECIOUS: $(STLDICTS_SRC)

# used in the main Makefile
ALLLIBS    += $(STLDICTS)
ALLMAPS    += $(STLDICTSMAPS)
   
##### local rules #####
.PHONY:         all-$(MODNAME) clean-$(MODNAME) distclean-$(MODNAME)

include/%.h:    $(METAUTILSDIRI)/%.h
		cp $< $@

$(METAUTILSDS): $(METAUTILSH) $(METAUTILSL) $(ROOTCINTTMPDEP)
		$(MAKEDIR)
		@echo "Generating dictionary $@..."
		$(ROOTCINTTMP) -f $@ -c $(METAUTILSH) $(METAUTILSL)

all-$(MODNAME): $(METAUTILSO) $(METAUTILSDO) $(STLDICTS)

clean-$(MODNAME):
		@rm -f $(METAUTILSO) $(METAUTILSDO) $(STLDICTS_OBJ) \
		   $(STLDICTS_DEP)

clean::         clean-$(MODNAME)

distclean-$(MODNAME): clean-$(MODNAME)
		@rm -f $(METAUTILSDEP) $(METAUTILSDS) $(METAUTILSDH) \
		   $(STLDICTS_OBJ) $(STLDICTS_DEP) $(STLDICTS_SRC) \
		   $(STLDICTSMAPS)

distclean::     distclean-$(MODNAME)

##### extra rules ######
$(METAUTILSO): CXXFLAGS += $(METAUTILSCXXFLAGS)
$(METAUTILSO): $(LLVMDEP)
$(METAUTILSTO): CXXFLAGS += $(METAUTILSCXXFLAGS)
$(METAUTILSTO): $(LLVMDEP)
