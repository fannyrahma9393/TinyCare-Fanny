import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import Login from '../Login'

// Mock the useAuth hook
vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    login: vi.fn(),
  }),
}))

// Mock the useTheme hook
vi.mock('../../context/ThemeContext', () => ({
  useTheme: () => ({
    theme: 'light',
    setTheme: vi.fn(),
  }),
}))

// Mock react-router-dom
vi.mock('react-router-dom', () => ({
  useNavigate: () => vi.fn(),
}))

describe('Login Component', () => {
  it('renders login form', () => {
    render(<Login />)
    
    // Check if TinyCare title is displayed (appears in brand and mobile logo sections)
    expect(screen.getAllByText('TinyCare').length).toBeGreaterThanOrEqual(1)
    
    // Check if subtitle text is displayed
    expect(screen.getByText('Care that feels personal.')).toBeInTheDocument()
    
    // Check if login form heading is present
    expect(screen.getByRole('heading', { name: 'Masuk' })).toBeInTheDocument()
  })

  it('has email and password input fields', () => {
    render(<Login />)
    
    // Check if email field exists
    expect(screen.getByPlaceholderText('email@tinycare.com')).toBeInTheDocument()
    
    // Check if password field exists
    expect(screen.getByPlaceholderText('••••••••')).toBeInTheDocument()
  })

  it('has submit button', () => {
    render(<Login />)
    
    // Check if submit button exists
    expect(screen.getByRole('button', { name: /masuk/i })).toBeInTheDocument()
  })
})
