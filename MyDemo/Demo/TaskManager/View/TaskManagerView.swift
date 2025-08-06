//
//  TaskManagerView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/05.
//

import SwiftUI

struct TaskManagerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = TaskManagerViewModel()
    @Namespace private var namespace
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                headerView
                weekDayView
                    .frame(height: 80)
                    .padding(.vertical, 5)
                    .offset(y: 5)
                scrollHeader
            }
            .padding([.top, .horizontal], 15)
            .padding(.bottom, 10)

            taskScrollView
        }
        .background(.mainBackground3)
        .onAppear {
            guard viewModel.selectedDate == nil else { return }
            viewModel.selectedDate = viewModel.currentWeek.first(where: { $0.date.isSameDay(as: .now) })?.date
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    var headerView: some View {
        HStack {
            Image(systemName: "chevron.left")
                .foregroundStyle(.white)
                .onTapGesture {
                    dismiss()
                }
            Text("This Week")
                .font(.title.bold())
                .foregroundStyle(.white)

            Spacer()
            Image(.FV)
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        }
    }

    var weekDayView: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.currentWeek) { day in
                let date = day.date
                let isToday = date.isSameDay(as: viewModel.selectedDate)
                VStack {
                    Text(day.date.string("EEE"))
                        .font(.caption)
                        .foregroundStyle(.white)
                    Text(day.date.string("dd"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(isToday ? .black : .white)
                        .frame(width: 38, height: 38)
                        .background {
                            if isToday {
                                Circle()
                                    .fill(Color.white)
                                    .matchedGeometryEffect(id: "SELECTEDDAY", in: namespace)
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
                .onTapGesture {
                    guard viewModel.selectedDate != date else { return }
                    withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                        viewModel.selectedDate = date
                    }
                }
            }
        }
    }

    var taskScrollView: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ScrollView(.vertical) {
                LazyVStack(spacing: 15, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.currentWeek) { day in
                        let date = day.date
                        let isLast = viewModel.currentWeek.last?.id == day.id
                        Section {
                            VStack(alignment: .leading) {
                                if viewModel.isEmptyDay {
                                    emptyTaskRow
                                } else {
                                    taskRowView
                                    taskRowView
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.leading, 70)
                            .padding(.top, -70)
                            .padding(.bottom, 10)
                            .frame(height: isLast ? size.height - 110 : nil, alignment: .top)
                        } header: {
                            VStack(spacing: 4) {
                                Text(date.string("EEE"))
                                Text(date.string("dd"))
                                    .font(.largeTitle.bold())
                            }
                            .frame(width: 55, height: 70)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.all, 20, for: .scrollContent)
            .contentMargins(.vertical, 20, for: .scrollIndicators)
            .scrollPosition(
                id: .init(
                    get: { 
                        return viewModel.currentWeek.first(where: { $0.date.isSameDay(as: viewModel.selectedDate) })?.id },
                    set: { newValue in
                        viewModel.selectedDate = viewModel.currentWeek.first(where: { $0.id == newValue })?.date }
                ),
                anchor: .top
            )
            .padding(.bottom, -70)
            .safeAreaPadding(.bottom, 70)
        }
        .background(.background)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 30, style: .continuous))
        .ignoresSafeArea(.all, edges: .bottom)
    }

    var scrollHeader: some View {
        HStack {
            Text(viewModel.selectedDate?.string("MMM") ?? "")
            Spacer()
            Text(viewModel.selectedDate?.string("YYYY") ?? "")
        }
        .font(.caption2)
        .environment(\.colorScheme, .dark)
    }

    var taskRowView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Circle()
                .foregroundStyle(.red)
                .frame(width: 5, height: 5)
            Text("Some Random Task")
                .font(.system(size: 14))
                .fontWeight(.semibold)
            HStack {
                Text("16:00 - 17:00")
                Spacer()
                Text("Some place, Califiornia")
            }
            .font(.caption)
            .foregroundStyle(.gray)
            .padding(.top, 5)
        }
        .lineLimit(1)
        .padding(15)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.background)
                .shadow(color: .black.opacity(0.35), radius: 1)
        }
    }

    var emptyTaskRow: some View {
        VStack(spacing: 8) {
            Text("No Task's Found on this Day!")

            Text("Try Adding some New Tasks!")
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TaskManagerView()
}
