                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                }
                .onAppear {
                    isAnimating = true
                }
                
                Text(NSLocalizedString("Preparing Download...", comment: ""))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(NSLocalizedString("Please wait", comment: ""))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            } 