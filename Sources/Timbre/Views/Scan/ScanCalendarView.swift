import SwiftUI

struct ScanCalendarView: View {
    let memos: [Memo]
    let onSelect: (Memo) -> Void

    @State private var currentDate = Date.now
    @State private var isMonthly = false

    private let calendar = Calendar.current
    private let weekDays = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]

    var body: some View {
        VStack(spacing: 0) {
            navigation
            dayHeaders
            if isMonthly {
                monthGrid
            } else {
                weekGrid
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Navigation

    private var navigation: some View {
        HStack(spacing: 12) {
            BubbleButton(icon: "chevron.left", size: 28, color: Color(hex: "0088FF")) {
                shift(by: isMonthly ? -30 : -7)
            }

            Spacer()

            Text(dateLabel)
                .font(TimbreFont.fontBold(size: 15))
                .foregroundStyle(Color(hex: "044060"))

            Spacer()

            // Weekly / monthly toggle
            TimbreTogglePill(label: "week", isSelected: !isMonthly) { isMonthly = false }
            TimbreTogglePill(label: "month", isSelected: isMonthly) { isMonthly = true }

            Spacer()

            BubbleButton(icon: "chevron.right", size: 28, color: Color(hex: "0088FF")) {
                shift(by: isMonthly ? 30 : 7)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var dayHeaders: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                Text(day)
                    .font(TimbreFont.fontBold(size: 12))
                    .foregroundStyle(Color(hex: "0088C8"))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Week grid

    private var weekGrid: some View {
        let start = calendar.startOfWeek(for: currentDate)
        return HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: start)!
                dayCell(date: date, compact: false)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Month grid

    private var monthGrid: some View {
        let weeks = weeksInMonth()
        return ScrollView {
            VStack(spacing: 4) {
                ForEach(weeks, id: \.self) { weekStart in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { offset in
                            let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
                            let inMonth = calendar.component(.month, from: date) ==
                                calendar.component(.month, from: currentDate)
                            dayCell(date: date, compact: true)
                                .opacity(inMonth ? 1.0 : 0.3)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Day cell

    private func dayCell(date: Date, compact: Bool) -> some View {
        let dayMemos = memosFor(date: date)
        let isToday = calendar.isDateInToday(date)

        return VStack(spacing: 3) {
            Text("\(calendar.component(.day, from: date))")
                .font(TimbreFont.fontBold(size: 14))
                .foregroundStyle(isToday ? Color(hex: "0088FF") : Color(hex: "044060"))

            VStack(spacing: 2) {
                ForEach(dayMemos.prefix(compact ? 2 : 3)) { memo in
                    Text(memo.title)
                        .font(TimbreFont.font(size: 11))
                        .foregroundStyle(Color(hex: "044060"))
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "00B0FF").opacity(0.12))
                        )
                        .onTapGesture { onSelect(memo) }
                }
                if dayMemos.count > (compact ? 2 : 3) {
                    Text("+\(dayMemos.count - (compact ? 2 : 3)) more")
                        .font(TimbreFont.font(size: 10))
                        .foregroundStyle(Color(hex: "0088C8"))
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 70 : 100)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isToday ? Color(hex: "00D8FF").opacity(0.08) : Color.white.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color(hex: "0080C0").opacity(0.1))
        )
    }

    // MARK: - Helpers

    private func memosFor(date: Date) -> [Memo] {
        memos.filter { calendar.isDate($0.displayDate, inSameDayAs: date) }
    }

    private func shift(by days: Int) {
        currentDate = calendar.date(byAdding: .day, value: days, to: currentDate) ?? currentDate
    }

    private var dateLabel: String {
        let fmt = DateFormatter()
        if isMonthly {
            fmt.dateFormat = "MMMM yyyy"
            return fmt.string(from: currentDate)
        } else {
            let start = calendar.startOfWeek(for: currentDate)
            let end = calendar.date(byAdding: .day, value: 6, to: start)!
            fmt.dateFormat = "MMM d"
            return "\(fmt.string(from: start)) – \(fmt.string(from: end))"
        }
    }

    private func weeksInMonth() -> [Date] {
        let comps = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }
        let lastOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: firstOfMonth)!
        let firstWeekStart = calendar.startOfWeek(for: firstOfMonth)
        let lastWeekStart = calendar.startOfWeek(for: lastOfMonth)

        var weeks: [Date] = []
        var current = firstWeekStart
        while current <= lastWeekStart {
            weeks.append(current)
            current = calendar.date(byAdding: .day, value: 7, to: current)!
        }
        return weeks
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? date
    }
}
