# HTK Support chuẩn bị

**Cài đặt HTK**

Đọc file install_note.txt

**Cài đặt Ruby 2.3**

> https://www.ruby-lang.org/en/downloads/

**Cài đặt thư viện**
(sau khi đã cài đặt xong HTK và Ruby)

```sh
$ gem install bundler
$ bundle install
```

Nhớ đứng ở thư mục chính

**Các tool bên ngoài**

`Microphone` nên có
`Audacity` phải có

# Steps
(if you don't understand any steps, better read EXPLAIN.md from now on)

(có vấn đề gì cứ mở file EXPLAIN.md)

**Làm lại make file nếu OS là Windows**

_Tự google cách chế lại `makefile` thành `batchfile`, nếu không thì tự copy từng dòng từ trên xuống để chạy_

**Chuẩn bị**

* 1. Đi thu âm (nếu chưa có 300 files thu âm)
* 2. Đem 300 files này bỏ vào thư mục train_wav
* 3. Chạy make prequisite để gen ra bộ đồ chơi cho train_wav
* 4. Chạy make testing_suggestion để người ta lựa file lựa phone cắt cho chuẩn
* 5. Xóa những file đã được lựa ở bước trên ra khỏi train_wav (không thì có khi nhận dạng 100%)
* 6. Bỏ các phone.wav (nhớ đặt tên giống từ điển) vào test_wav
* 7. Chạy make training ngồi chơi tầm 30-45 phút
* 8. Chạy make testing để lấy kết quả ở result.txt
* 9. Viết tài liệu, chém gió trăng hoa về kết quả mình đã làm

# Question/Answer

Q: Vì sao hồi trước làm bị lỗi hoài vậy

A: Vì bạn bị guide cũ nó lừa


Q: Tại sao không làm phone, dict chữ HOA

A: Sợ bug, `http://www.ling.ohio-state.edu/~bromberg/htk_problems.html`

Q: Có từ cắt kiểu gì cũng không nhận dạng đúng được, làm giảm % nhận dạng

A: Bỏ từ đó ra, dùng Audacity thu theo format mono 32 bit float 48000 Hz, lựa chỗ vắng lặng ngồi thu


Q: Tại sao lại có thư mục BAD với cái file badproto.txt

A: Vì từ điển của mình là từ điển rất rộng và *ngây thơ*, có một số phone như "q" không bao giờ đi lẻ mà phải dính với nhau "qu" (đố tìm ra từ nào xuất phát bằng q), mình phải loại những thằng này ra khỏi từ điển lẫn fulllist


Q: Chạy như thế nào?

A: Bạn mở Makefile, trong đó chứa lệnh theo từng cụm. Bạn đứng ở trên windows sẽ phải tự tạo batch file theo các lệnh từ trên xuống (không biết windows có cho 'echo' không)

Q: Mình chạy bị lỗi, mình không chạy được
A: Chắc chắn bạn đã cài đặt HTK đúng cách, cài ruby đúng cách (gọi được trong console) và bundle install được những thư viện trong Gemfile

Q: Tại sao tui thấy có code thừa, chưa được gọi
A: Tại lười phát triển tool mình thu qua micro rồi biết ngay là từ gì và lười xóa code ra

Q: Tại sao nên dùng tool này
A: Vì tool này tự tạo từ điển, tự fix lỗi, tự tạo lab file, suggest người ta nên cắt phone gì từ file nào trong audacity ... Giải quyết những vấn đề đau đầu khác

Q: Độ chính xác trung bình bao nhiêu
A: Tham số trong này mình không thay đổi so với recommend của thầy, tùy vào file bạn cắt có đúng trong Audacity hay không, trung bình là 20->40%

Q: Có thể tăng độ chính xác được không
A: Tự thu âm, nhớ là mono 32bit float 48000Hz (Hoặc bạn mở file được thu âm xem thông số của nó rồi setting lại trong Audacity)

# License

https://opensource.org/licenses/GPL-3.0

# Contact

Whisper me at vnkeymaster(at)gmail.com
