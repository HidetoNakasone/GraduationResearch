
*Created_at: 2020/05/22*

<!-- GraduationResearch -->

# メモ
- 別フォルダで作成を進めていた卒論用のWebAppが少し上手くいきそう。
- そういやGitで管理していなかった。
- ってことで、新しくフォルダを作成し、順番よく貼り付けてコミット管理していく。

---

## SQLメモ

create table words(id serial, word varchar(256), primary key(id));
insert into words(word) values
('青'),
('空');

create table urls(id serial, word_text varchar(256), url_text varchar(256), primary key(id));


