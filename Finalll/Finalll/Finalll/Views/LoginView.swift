//
//  LoginView.swift
//  Finalll
//
//  Created for MindEase
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Binding var isPresented: Bool
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // App Title
                VStack(spacing: 8) {
                    Text("MindEase")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your AI Emotional Companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.signIn()
                            if viewModel.isAuthenticated {
                                isPresented = false
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                    
                    HStack {
                        Text("Don't have an account?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Sign Up") {
                            showingSignUp = true
                        }
                        .font(.caption)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSignUp) {
                SignUpView(isPresented: $showingSignUp)
            }
        }
    }
}

#Preview {
    LoginView(isPresented: .constant(true))
}

