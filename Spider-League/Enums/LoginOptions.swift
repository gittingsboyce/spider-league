//
//  LoginOptions.swift
//  Spider League
//
//  Created by Gittings Boyce on 3/7/25.
//

enum LoginOption {
    case signInWithApple
    case signInWithGoogle
    case emailAndPassword(email: String, password: String)
}
