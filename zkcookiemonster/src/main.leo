// The 'cookie_monster' program.
program zkcookiemonster.aleo {
    struct CookieStats {
        cookie_type: u64,
        cookie_deliciousness: u64
    }

    record cookie {
        owner: address,
        gates: u64,
        cookie_info: CookieStats
    }

    transition bake_cookie(destination: address, cookieType: u64, deliciousness: u64) -> cookie {
        return cookie {
            owner: destination,
            gates: 0u64,
            cookie_info: CookieStats {
                cookie_type: cookieType,
                cookie_deliciousness: deliciousness
            }
        };
    }

    transition eat_cookie(cookieToEat: cookie) {
        // Om nom. Will mark record as spent on chain.
    }
}