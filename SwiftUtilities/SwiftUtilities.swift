/*
 * Open Directory Server - app for macOS Mojave
 * Copyright (C) 2020 William Kent
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

// The SwiftUtilities target serves to provide a common location for the
// code imported using the Swift Package Manager. Xcode only supports statically
// linking Swift Package Manager dependencies, which results in double-definition
// errors at runtime.

@_exported import SwiftKVO
@_exported import LocalizedString
@_exported import AuthorizationAPI
