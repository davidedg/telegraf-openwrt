include $(TOPDIR)/rules.mk

PKG_NAME:=telegraf
PKG_VERSION:=1.34.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/influxdata/telegraf/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=0bdaf8c8e306bbf514418c7de1da00d5d1ba14617ba69eacdd13f6796e4ff4ea

PKG_MAINTAINER:=Davide Del Grande <delgrande.davide@gmail.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/influxdata/telegraf
GO_PKG_BUILD_PKG:=github.com/influxdata/telegraf/cmd/telegraf
GO_PKG_LDFLAGS:=-s -w
GO_PKG_LDFLAGS_X:=main.version=$(PKG_VERSION)


include $(INCLUDE_DIR)/package.mk
include ../../lang/golang/golang-package.mk


define Package/$(PKG_NAME)/Default
    TITLE:=Telegraf
    SECTION:=utils
    CATEGORY:=Utilities
    URL:=https://github.com/influxdata/telegraf
    DEPENDS:=$(GO_ARCH_DEPENDS)
    BUILD_DEPENDS:=upx/host
endef

define Package/$(PKG_NAME)/Default/description
    Telegraf is a plugin-driven agent for collecting and sending metrics and events.
    It supports various inputs (including prometheus endpoints) and outputs (e.g. Prometheus, InfluxDB).
endef

define Package/$(PKG_NAME)/Default/conffiles
/etc/telegraf.conf
endef


define Package/$(PKG_NAME)
  $(call Package/$(PKG_NAME)/Default)
endef


define Package/$(PKG_NAME)/install
  true
endef


define Build/Prepare
	@echo "----------------------------------------------------------"
	@echo "Build/Prepare - VARIANT:$(BUILD_VARIANT)"
	@echo "----------------------------------------------------------"

	@which upx || (echo "--- UPX is not installed. Please install UPX to continue." && exit 1)

	$(call Build/Prepare/Default)
endef


define Build/Compile
	@echo "----------------------------------------------------------"
	@echo "Build/Compile - VARIANT:$(BUILD_VARIANT) - Tags: $(GO_BUILD_TAGS)"
	@echo "----------------------------------------------------------"

	$(call GoPackage/Build/Compile,-tags $(GO_BUILD_TAGS))
endef


define Package/$(PKG_NAME)/Default/install
	@echo "----------------------------------------------------------"
	@echo "INSTALL - VARIANT:$(BUILD_VARIANT)"
	@echo "----------------------------------------------------------"

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) files/etc/init.d/telegraf $(1)/etc/init.d/telegraf
	$(INSTALL_CONF) files/etc/telegraf.conf.* $(1)/etc/
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/cmd/telegraf/agent.conf $(1)/etc/telegraf.conf.default

# keep 2 dollar signs for proper escaping when called from within a nested define
	$$(call GoPackage/Package/Install/Bin,$(1))

	upx --lzma $(1)/usr/bin/telegraf
endef



define BuildVariant
  define Package/$(PKG_NAME)-$(1)/install
    $(call Package/$(PKG_NAME)/Default/install,$$1,$(1))
  endef

  define Package/$(PKG_NAME)-$(1)
    $(call Package/$(PKG_NAME))
    VARIANT:=$(1)
    TITLE+= ($(1))
  endef

  define Package/$(PKG_NAME)-$(1)/description
    $(call Package/$(PKG_NAME)/Default/description)
    Variant: $(1)
    BuildTags: $(GO_BUILD_TAGS)
  endef

  define Package/$(PKG_NAME)-$(1)/conffiles
  $(call Package/$(PKG_NAME)/Default/conffiles)
  endef

  $$(eval $$(call BuildPackage,$(PKG_NAME)-$(1)))
endef


VARIANTS := \
	collectdsock2influxgrcloud \
	fake

ifeq ($(BUILD_VARIANT),collectdsock2influxgrcloud)
GO_BUILD_TAGS:=custom,inputs.socket_listener,outputs.influxdb,parsers.collectd
endif

ifeq ($(BUILD_VARIANT),fake)
GO_BUILD_TAGS:=custom,inputs.socket_listener
endif


$(foreach v,$(VARIANTS), $(eval $(call BuildVariant,$(v))))
