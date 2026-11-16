#include "decoration.h"

#include <KPluginFactory>

K_PLUGIN_FACTORY_WITH_JSON(DockyardGlassDecorationFactory, "dockyardglass.json", registerPlugin<DockyardGlass::Decoration>();)

#include "plugin.moc"
