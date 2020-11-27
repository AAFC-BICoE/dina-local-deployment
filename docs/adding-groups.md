# Adding A Group

## Using the Keycloak Console

Select "Groups" from the side bar menu. This will show the current list of groups and let you manage them. Adding a new group is simple - click the "New" button and enter the group's name. After that you can add attributes, associate roles, change the group name or view membership from the appropriate tabs. Sub-groups can be added from the main groups menu by selecting an existing group and adding a new group. In DINA, we use sub-groups to automatically apply roles (e.g. "/cnc/staff" members will have the "staff" role), which is done under the Role Mappings tab when editing a group.

In order to permanently add a group to our deployment image, it must be added in the `keycloak-dina-starter-realm.json` file. This can be done by exporting the realm (Export in the side bar menu), ensuring that the "Export groups and roles" checkbox is on. The groups can then be copied to the starter realm from the exported json. Note: The starter realm json **must not** be overwritten with the exported realm, because Keycloak omits some necessary items from the exported json.

## Adding Groups Directly In JSON

In the `keycloak-dina-starter-realm.json`, there is a "groups" structure with child elements that represent the groups. The structure of a group element is like this:

```
{
  "id": "bdb5572b-2352-4926-90e5-4594d21e6df0",
  "name": "aafc",
  "path": "/aafc",
  "attributes": {},
  "realmRoles": [],
  "clientRoles": {},
  "subGroups": [ ... ]
}
```

The simplest way to create a new DINA group is to copy one of the existing groups, along with its subgroups and role associations. After that, update the name and paths, and generate new UUIDs for each item.

## Importing Groups Into An Existing Realm

The realm JSON, including groups, can be partially imported using the Import function in the sidebar menu. First, select the json file. Once it's selected, you have an opportunity to review it and specify some settings before importing. For this task, we want only the groups toggle turned on, and the "If resource exists" dropdown set to "skip".

After importing, you will see a results screen that should have the existing top-level groups marked as "skipped", along with the imported group marked "added". It will only show and count top-level groups (e.g. "aafc", "dao"), but the subgroups defined within them will still be imported and will show up in the groups list.

When an imported top-level group already exists, Keycloak will not process that group at all, so subgroups can't be imported in this way. Importing with the "overwrite" option will allow the groups to be imported, but doing so will remove all existing group memberships in that group.
