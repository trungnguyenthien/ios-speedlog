import Foundation

class SpeedLog {
    static let t0 = Date()
    private static var printedHeader = false
    private static var lastActionTime = Date()
    private static var lastDataTime: Date? = nil
    static var logFunc: (_ message: String) -> Void = { msg in
        print(tag + msg)
    }
    private static let tag = "[SLOG]"
    
    private class func printHeaderIfNeed() {
        if printedHeader {
            return
        }
        logFunc("| view | action/type | max | duration | cls | |")
        logFunc("|---|---|---:|---:|---:|---:|")
        printedHeader = true
    }
    
    private class func printRow(
        view: String,
        isAction: Bool,
        name: String,
        maxDuration: String? = nil,
        duration: Double? = nil,
        cls: Double? = nil,
        isOK: Bool? = nil
    ) {
        let nameColumnValue = (isAction ? "⚡️" : "🎯") + name
        
        var maxDurationColumnValue = "---"
        if let maxDuration = maxDuration {
            maxDurationColumnValue = "\(maxDuration)"
        }
        
        var durationColumnValue = "---"
        if let duration = duration {
            durationColumnValue = "\(duration)"
        }
        var clsColumnValue = "---"
        if let cls = cls {
            clsColumnValue = "\(cls)"
        }
        var alertColumnValue = "---"
        if let isOK = isOK {
            alertColumnValue = !isOK ? "❌" : "✅"
        }
        logFunc("| \(view) | \(nameColumnValue) | \(maxDurationColumnValue) | \(durationColumnValue) | \(clsColumnValue) | \(alertColumnValue) |")
    }
    
    private class func printBlankRow() {
        logFunc("| --- | --- | --- | --- | --- | --- |")
    }
    
    // Return thời gian từ start đến end, tính bằng giây và lấy 3 số lẻ phần thập phân
    private class func calDuration(start: Date, end: Date) -> Double {
        let timeInterval = end.timeIntervalSince(start)
        return Double(round(timeInterval * 1000) / 1000)
    }
    
    class func begin(view: String, action: String) {
        lastActionTime = Date()
        lastDataTime = nil
        printHeaderIfNeed()
        printBlankRow()
        printRow(
            view: view,
            isAction: true,
            name: action
        )
    }
    
    class func finish(view: String = "app", customType: String, maxDuration: Double? = nil) {
        printHeaderIfNeed()
        let duration = calDuration(start: lastActionTime, end: Date())
        var max = 999999999.0
        if let maxDuration = maxDuration {
            max = maxDuration
        }
        printRow(
            view: view,
            isAction: false,
            name: customType,
            maxDuration: maxDuration == nil ? "---" : "\(maxDuration!)",
            duration: duration,
            isOK: duration <= max
        )
    }
    
    // Hoàn tất quá trình transition hoặc present một view mới
    // Việc kết thúc này không đồng thời với việc layout view đã cố định hoặc việc render data đã hoàn tất.
    class func finishAppear(view: String = "app") {
        finish(view: view, customType: "view_appeared", maxDuration: 1.0)
    }
    
    class func finishShowIndicator(view: String = "app") {
        finish(view: view, customType: "indicator_appeared", maxDuration: 0.3)
    }
    
    // Hoàn tất việc hiển thị data trên view
    class func finishUpdateData(view: String = "app") {
        var cls: Double = 0
        let current = Date()
        if let lastDataTime = lastDataTime {
            cls = calDuration(start: lastDataTime, end: current)
        } else {
            // Chỉ update lastDataTime một lần duy nhất, đó là lần đầu tiên có data
            // Từ các lần sau sẽ bắt đầu tính chỉ số cls
            lastDataTime = current
        }
        printHeaderIfNeed()
        let duration = calDuration(start: lastActionTime, end: Date())
        printRow(
            view: view,
            isAction: false,
            name: "view_updated",
            maxDuration: "2/0.5",
            duration: duration,
            cls: cls,
            isOK: duration <= 2 && cls <= 0.5
        )
    }
}
