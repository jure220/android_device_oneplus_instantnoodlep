// dispcfg -- list and switch the primary display's mode through QTI's
// vendor IDisplayConfig service.
//
// The stock hwcomposer advertises exactly ONE config to the compositor (the
// mode the panel booted into), so Mir has nothing to switch to. OxygenOS
// changes resolution/refresh through this vendor interface instead, which is
// what this tool drives.
//
//   dispcfg list          enumerate configs, mark the active one
//   dispcfg set <index>   make <index> active

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <config/client_interface.h>

using DisplayConfig::ClientInterface;
using DisplayConfig::ConfigCallback;
using DisplayConfig::DisplayType;
using DisplayConfig::Attributes;

namespace {

class Callback : public ConfigCallback {};

double hz_of(uint32_t vsync_period_ns) {
  return vsync_period_ns ? 1e9 / static_cast<double>(vsync_period_ns) : 0.0;
}

int list(ClientInterface *intf) {
  uint32_t count = 0, active = 0;
  int err = intf->GetConfigCount(DisplayType::kPrimary, &count);
  if (err) {
    fprintf(stderr, "GetConfigCount failed: %d\n", err);
    return 1;
  }
  err = intf->GetActiveConfig(DisplayType::kPrimary, &active);
  if (err) {
    fprintf(stderr, "GetActiveConfig failed: %d\n", err);
    return 1;
  }
  printf("configs: %u   active: %u\n", count, active);
  for (uint32_t i = 0; i < count; i++) {
    Attributes a;
    err = intf->GetDisplayAttributes(i, DisplayType::kPrimary, &a);
    if (err) {
      printf("  [%u] GetDisplayAttributes failed: %d\n", i, err);
      continue;
    }
    printf("  %s[%u] %ux%u  vsync_period=%u ns  = %.1f Hz\n",
           i == active ? "* " : "  ", i, a.x_res, a.y_res, a.vsync_period,
           hz_of(a.vsync_period));
  }
  return 0;
}

int set(ClientInterface *intf, uint32_t index) {
  uint32_t count = 0;
  if (intf->GetConfigCount(DisplayType::kPrimary, &count) == 0 && index >= count) {
    fprintf(stderr, "index %u out of range (%u configs)\n", index, count);
    return 1;
  }
  int err = intf->SetActiveConfig(DisplayType::kPrimary, index);
  if (err) {
    fprintf(stderr, "SetActiveConfig(%u) failed: %d\n", index, err);
    return 1;
  }
  uint32_t active = 0;
  intf->GetActiveConfig(DisplayType::kPrimary, &active);
  printf("SetActiveConfig(%u) ok, active is now %u\n", index, active);
  return active == index ? 0 : 1;
}

}  // namespace

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "usage: %s list | set <index>\n", argv[0]);
    return 2;
  }

  Callback cb;
  ClientInterface *intf = nullptr;
  int err = ClientInterface::Create("dispcfg", &cb, &intf);
  if (err || !intf) {
    fprintf(stderr, "ClientInterface::Create failed: %d\n", err);
    return 1;
  }

  int rc;
  if (!strcmp(argv[1], "list")) {
    rc = list(intf);
  } else if (!strcmp(argv[1], "set") && argc == 3) {
    rc = set(intf, static_cast<uint32_t>(strtoul(argv[2], nullptr, 10)));
  } else {
    fprintf(stderr, "usage: %s list | set <index>\n", argv[0]);
    rc = 2;
  }

  ClientInterface::Destroy(intf);
  return rc;
}
