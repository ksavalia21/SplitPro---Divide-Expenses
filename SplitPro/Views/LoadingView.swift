//
//  LoadingView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// LoadingView: A simple view displayed while the app is determining authentication state
///
/// This view is shown when the app first launches and is checking if a user session exists.
/// It provides visual feedback to the user that the app is working.
struct LoadingView: View {
    var body: some View {
        ZStack {
            // Background color covering the entire screen
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App branding/logo
                Image(systemName: "dollarsign.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                // App name
                Text("SplitPro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Loading indicator
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.top, 20)
                
                // Loading text
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LoadingView()
}

