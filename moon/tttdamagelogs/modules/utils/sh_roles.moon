dmglog.IsTeamkill = (role1, role2) ->
    return role1 == role2 or (role1 == ROLE_DETECTIVE and role2 == ROLE_INNOCENT) or (role2 == ROLE_INNOCENT and role2 == ROLE_DETECTIVE)