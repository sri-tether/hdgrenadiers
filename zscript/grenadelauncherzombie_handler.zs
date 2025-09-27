// ------------------------------------------------------------
// Grenade launcher zombie spawn handler
// ------------------------------------------------------------

class HDGLZHandler : EventHandler
{
    override void CheckReplacement(ReplaceEvent e)
    {
        if (!e.Replacement)
        {
            return;
        }

        CVar cv = CVar.GetCVar("hdglz_grenadierreplacerate");
        float rate = 0.0;
        if (cv != null) {
            rate = max(0.0, min(1.0, cv.GetFloat()));
        }
        // grenadiers were way too common
        rate = rate / 15.0;

        let cname = e.Replacement.GetClassName();
        switch (cname)
        {
            case 'ZombieStormtrooper':
            case 'ZombieAutoStormtrooper':
            case 'ZombieSemiStormtrooper':
            case 'ZombieSMGStormtrooper':
            case 'ZombieHideousTrooper':
//                 if (rate >= 1.0 || (rate > 0.0 && frandom(0.0, 1.0) < rate))
//                 {
                    e.Replacement = "HDGrenadier";
//                 }
                break;

            case 'DeadZombieStormtrooper':
            case 'DeadZombieAutoStormtrooper':
            case 'DeadZombieSemiStormtrooper':
            case 'DeadZombieSMGStormtrooper':
                if (rate >= 1.0 || (rate > 0.0 && frandom(0.0, 1.0) < rate))
                {
                    e.Replacement = "DeadGrenadier";
                }
                break;

            case 'HideousJackbootReplacer':
                if (rate >= 1.0 || (rate > 0.0 && frandom(0.0, 1.0) < rate))
                {
                    e.Replacement = "HDGrenadier";
                }
                break;

            case 'DeadZombieShotgunner': 
                if (rate >= 1.0 || (rate > 0.0 && frandom(0.0, 1.0) < rate))
                {
                    e.Replacement = "DeadGrenadier";
                }
                break;

            default:
                break;
        }
    }
}
