//
//  OpenAIService.swift
//  SimpleChatForMac
//
//  Created by shiyanjun on 2023/12/11.
//

import Alamofire

class OpenAIService {
    private let endpointUrl = "https://api.openai.com/v1/chat/completions"
    
    /// 发送消息
    func sendMessage(messages: [Message], apiKey: String? = "") async -> Result<OpenAIChatResponse, Error> {
        guard let _ = apiKey else {
            return .failure(CustomError.error_info("请先配置密钥！"))
        }
        
        if apiKey!.isEmpty {
            return .failure(CustomError.error_info("请先配置密钥！"))
        }
        
        let openAIMessages = messages.map({OpenAIChatMessage(role: $0.role, content: $0.content)})
        let body = OpenAIChatBody(model: "gpt-3.5-turbo", messages: openAIMessages)
        let headers: HTTPHeaders = ["Authorization": "Bearer \(apiKey!)"]
        
        let dataRequest = AF.request(endpointUrl, method: .post, parameters: body, encoder: .json, headers: headers)
        
        do {
            let successResponse = try await dataRequest.serializingDecodable(OpenAIChatResponse.self).value
            print("请求成功:\(successResponse.choices.count)")
            return .success(successResponse)
        } catch(let error) {
            if let afError = error as? AFError {
                switch afError {
                case .sessionTaskFailed:
                    // 网络连接失败
                    print("连接网络失败，请检查您的网络！")
                    return .failure(CustomError.error_info("连接网络失败，请检查您的网络！"))
                default:
                    // 其他Alamofire错误处理
                    break
                }
            }
            do {
                let errorResponse = try await dataRequest.serializingDecodable(OpenAIErrorResponse.self).value
                print("请求失败1:\(errorResponse.error)")
                if errorResponse.error.code == "invalid_api_key" {
                    return .failure(CustomError.error_info("请提供一个有效的API Key!"))
                }
                if errorResponse.error.code == "model_not_found" {
                    return .failure(CustomError.error_info("您选择的模型不存在!"))
                }
                
                if errorResponse.error.code == "context_length_exceeded" {
                    return .failure(CustomError.error_info("此模型的最大上下文长度为4097个令牌。然而，您的消息产生了4115个令牌。请缩短消息的长度!"))
                }
                
                return .failure(CustomError.error_info(errorResponse.error.message))
            } catch {
                print("请求失败2:\(error.localizedDescription)")
                return .failure(CustomError.error_info("请求服务异常，请稍后再试！"))
            }
        }
    }
    
}

enum CustomError: Error {
    case error_info(String)
}

struct OpenAIChatBody: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
}

struct OpenAIChatMessage: Codable {
    let role: SenderRole
    let content: String
}

enum SenderRole: String, Codable {
    case system
    case user
    case assistant
}

struct OpenAIChatResponse: Decodable {
    let choices: [OpenAIChatChoice]
}

struct OpenAIChatChoice: Decodable {
    let message: OpenAIChatMessage
}


struct OpenAIErrorResponse: Decodable {
    let error: OpenAIErrorMessage
}

struct OpenAIErrorMessage: Decodable {
    let message: String
    let type: String
    let code: String
}

