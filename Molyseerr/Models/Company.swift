//
//  Company.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import Foundation

/// Represents a production company (studio) or TV network
struct Company: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let logoPath: String?

    /// Full TMDB logo URL with duotone filter (matches webapp exactly)
    var logoURL: URL? {
        guard let logoPath = logoPath else { return nil }
        let baseURL = "https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)"
        return URL(string: "\(baseURL)\(logoPath)")
    }
}

// MARK: - Hardcoded Studios List

extension Company {
    /// List of major movie studios
    /// Matches Seerr web app: src/components/Discover/StudioSlider/index.tsx
    static let studios: [Company] = [
        Company(
            id: 2,
            name: "Disney",
            logoPath: "/wdrCwmRnLFJhEoH8GSfymY85KHT.png"
        ),
        Company(
            id: 127928,
            name: "20th Century Studios",
            logoPath: "/h0rjX5vjW5r8yEnUBStFarjcLT4.png"
        ),
        Company(
            id: 34,
            name: "Sony Pictures",
            logoPath: "/GagSvqWlyPdkFHMfQ3pNq6ix9P.png"
        ),
        Company(
            id: 174,
            name: "Warner Bros. Pictures",
            logoPath: "/ky0xOc5OrhzkZ1N6KyUxacfQsCk.png"
        ),
        Company(
            id: 33,
            name: "Universal Pictures",
            logoPath: "/8lvHyhjr8oUKOOy2dKXoALWKdp0.png"
        ),
        Company(
            id: 4,
            name: "Paramount Pictures",
            logoPath: "/fycMZt242LVjagMByZOLUGbCvv3.png"
        ),
        Company(
            id: 3,
            name: "Pixar",
            logoPath: "/1TjvGVDMYsj6JBxOAkUHpPEwLf7.png"
        ),
        Company(
            id: 521,
            name: "DreamWorks Animation",
            logoPath: "/kP7t6RwGz2AvvTkvnI1uteEwHet.png"
        ),
        Company(
            id: 420,
            name: "Marvel Studios",
            logoPath: "/hUzeosd33nzE5MCNsZxCGEKTXaQ.png"
        ),
        Company(
            id: 9993,
            name: "DC Films",
            logoPath: "/2Tc1P3Ac8M479naPp1kYT3izLS5.png"
        ),
        Company(
            id: 41077,
            name: "A24",
            logoPath: "/1ZXsGaFPgrgS6ZZGS37AqD5uU12.png"
        )
    ]
}

// MARK: - Hardcoded Networks List

extension Company {
    /// List of major TV networks
    /// Matches Seerr web app: src/components/Discover/NetworkSlider/index.tsx
    static let networks: [Company] = [
        Company(
            id: 213,
            name: "Netflix",
            logoPath: "/wwemzKWzjKYJFfCeiB57q3r4Bcm.png"
        ),
        Company(
            id: 2739,
            name: "Disney+",
            logoPath: "/gJ8VX6JSu3ciXHuC2dDGAo2lvwM.png"
        ),
        Company(
            id: 1024,
            name: "Prime Video",
            logoPath: "/ifhbNuuVnlwYy5oXA5VIb2YR8AZ.png"
        ),
        Company(
            id: 2552,
            name: "Apple TV+",
            logoPath: "/4KAy34EHvRM25Ih8wb82AuGU7zJ.png"
        ),
        Company(
            id: 453,
            name: "Hulu",
            logoPath: "/pqUTCleNUiTLAVlelGxUgWn1ELh.png"
        ),
        Company(
            id: 49,
            name: "HBO",
            logoPath: "/tuomPhY2UtuPTqqFnKMVHvSb724.png"
        ),
        Company(
            id: 4330,
            name: "Discovery+",
            logoPath: "/1D1bS3Dyw4ScYnFWTlBOvJXC3nb.png"
        ),
        Company(
            id: 2,
            name: "ABC",
            logoPath: "/ndAvF4JLsliGreX87jAc9GdjmJY.png"
        ),
        Company(
            id: 19,
            name: "FOX",
            logoPath: "/1DSpHrWyOORkL9N2QHX7Adt31mQ.png"
        ),
        Company(
            id: 359,
            name: "Cinemax",
            logoPath: "/6mSHSquNpfLgDdv6VnOOvC5Uz2h.png"
        ),
        Company(
            id: 174,
            name: "AMC",
            logoPath: "/pmvRmATOCaDykE6JrVoeYxlFHw3.png"
        ),
        Company(
            id: 67,
            name: "Showtime",
            logoPath: "/Allse9kbjiP6ExaQrnSpIhkurEi.png"
        ),
        Company(
            id: 318,
            name: "Starz",
            logoPath: "/8GJjw3HHsAJYwIWKIPBPfqMxlEa.png"
        ),
        Company(
            id: 71,
            name: "The CW",
            logoPath: "/ge9hzeaU7nMtQ4PjkFlc68dGAJ9.png"
        ),
        Company(
            id: 6,
            name: "NBC",
            logoPath: "/o3OedEP0f9mfZr33jz2BfXOUK5.png"
        ),
        Company(
            id: 16,
            name: "CBS",
            logoPath: "/nm8d7P7MJNiBLdgIzUK0gkuEA4r.png"
        ),
        Company(
            id: 4353,
            name: "Paramount+",
            logoPath: "/fi83B1oztoS47xxcemFdPMhIzK.png"
        ),
        Company(
            id: 4,
            name: "BBC One",
            logoPath: "/mVn7xESaTNmjBUyUtGNvDQd3CT1.png"
        ),
        Company(
            id: 56,
            name: "Cartoon Network",
            logoPath: "/c5OC6oVCg6QP4eqzW6XIq17CQjI.png"
        ),
        Company(
            id: 80,
            name: "Adult Swim",
            logoPath: "/9AKyspxVzywuaMuZ1Bvilu8sXly.png"
        ),
        Company(
            id: 13,
            name: "Nickelodeon",
            logoPath: "/ikZXxg6GnwpzqiZbRPhJGaZapqB.png"
        ),
        Company(
            id: 3353,
            name: "Peacock",
            logoPath: "/gIAcGTjKKr0KOHL5s4O36roJ8p7.png"
        )
    ]
}
