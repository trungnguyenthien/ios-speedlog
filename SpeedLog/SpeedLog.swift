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
        logFunc("| view | action/type | duration(s) | cls(s) | |")
        logFunc("|---|---|---:|---:|---:|")
        printedHeader = true
    }
    
    private class func printRow(
        view: String,
        isAction: Bool,
        name: String,
        duration: Double? = nil,
        cls: Double? = nil,
        isOK: Bool? = nil
    ) {
        let nameColumnValue = (isAction ? "⚡️" : "🎯") + name
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
        logFunc("| \(view) | \(nameColumnValue) | \(durationColumnValue) | \(clsColumnValue) | \(alertColumnValue) |")
    }
    
    private class func printBlankRow() {
        logFunc("| --- | --- | --- | --- | --- |")
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
    
    // Hoàn tất quá trình transition hoặc present một view mới
    // Việc kết thúc này không đồng thời với việc layout view đã cố định hoặc việc render data đã hoàn tất.
    class func finishAppear(view: String = "app") {
        printHeaderIfNeed()
        let duration = calDuration(start: lastActionTime, end: Date())
        printRow(
            view: view,
            isAction: false,
            name: "view_appeared",
            duration: duration,
            isOK: duration <= 1
        )
    }
    
    class func finishShowIndicator(view: String = "app") {
        printHeaderIfNeed()
        let duration = calDuration(start: lastActionTime, end: Date())
        printRow(
            view: view,
            isAction: false,
            name: "indicator_appeared",
            duration: duration,
            isOK: duration <= 0.3
        )
    }
    
    class func finish(view: String = "app", customType: String) {
        printHeaderIfNeed()
        let duration = calDuration(start: lastActionTime, end: Date())
        printRow(
            view: view,
            isAction: false,
            name: customType,
            duration: duration
        )
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
            duration: duration,
            cls: cls,
            isOK: duration <= 2 && cls <= 0.5
        )
    }
}
