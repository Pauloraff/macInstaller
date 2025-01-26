//
//  WebViewData.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//


import WebKit

class WebViewData: ObservableObject {
  @Published var loading: Bool = false
  @Published var url: URL?;

  init (url: URL) {
    self.url = url
  }
}
