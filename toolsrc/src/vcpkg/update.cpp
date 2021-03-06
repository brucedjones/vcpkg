#include "pch.h"

#include <vcpkg/base/system.h>
#include <vcpkg/commands.h>
#include <vcpkg/help.h>
#include <vcpkg/paragraphs.h>
#include <vcpkg/update.h>
#include <vcpkg/vcpkglib.h>

namespace vcpkg::Update
{
    bool OutdatedPackage::compare_by_name(const OutdatedPackage& left, const OutdatedPackage& right)
    {
        return left.spec.name() < right.spec.name();
    }

    std::vector<OutdatedPackage> find_outdated_packages(const Dependencies::PortFileProvider& provider,
                                                        const StatusParagraphs& status_db)
    {
        const std::vector<StatusParagraph*> installed_packages = get_installed_ports(status_db);

        std::vector<OutdatedPackage> output;
        for (const StatusParagraph* pgh : installed_packages)
        {
            if (!pgh->package.feature.empty())
            {
                // Skip feature paragraphs; only consider master paragraphs for needing updates.
                continue;
            }

            auto maybe_scf = provider.get_control_file(pgh->package.spec.name());
            if (auto p_scf = maybe_scf.get())
            {
                auto&& port_version = p_scf->core_paragraph->version;
                auto&& installed_version = pgh->package.version;
                if (installed_version != port_version)
                {
                    output.push_back({pgh->package.spec, VersionDiff(installed_version, port_version)});
                }
            }
            else
            {
                // No portfile available
            }
        }

        return output;
    }

    const CommandStructure COMMAND_STRUCTURE = {
        Help::create_example_string("update"),
        0,
        0,
        {},
        nullptr,
    };

    void perform_and_exit(const VcpkgCmdArguments& args, const VcpkgPaths& paths)
    {
        args.parse_arguments(COMMAND_STRUCTURE);
        System::println("Using local portfile versions. To update the local portfiles, use `git pull`.");

        const StatusParagraphs status_db = database_load_check(paths);

        Dependencies::PathsPortFileProvider provider(paths);

        const auto outdated_packages = SortedVector<OutdatedPackage>(find_outdated_packages(provider, status_db),
                                                                     &OutdatedPackage::compare_by_name);

        if (outdated_packages.empty())
        {
            System::println("No packages need updating.");
        }
        else
        {
            System::println("The following packages differ from their port versions:");
            for (auto&& package : outdated_packages)
            {
                System::println("    %-32s %s", package.spec, package.version_diff.to_string());
            }
            System::println("\n"
                            "To update these packages and all dependencies, run\n"
                            "    .\\vcpkg upgrade\n"
                            "\n"
                            "To only remove outdated packages, run\n"
                            "    .\\vcpkg remove --outdated\n");
        }

        Checks::exit_success(VCPKG_LINE_INFO);
    }
}
