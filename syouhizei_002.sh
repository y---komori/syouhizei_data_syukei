#!/bin/bash
# syouhizei_002.sh  2019.5.6

###########################################################################
# このスクリプトについて
# 概要
# 消費税明細書データから、消費税計算で必要な歳入データを並べ替え及び集計する
# syouhizei_001.shは歳出データ集計


# 処理フロー
# 1.課税、非課税、不課税データを目、節で並び替え、データ保存 
# 2.データ集計を実行、結果を保存

# 使い方
# !!このディレクトリに移動後、右クリックで git bash起動後、 $ ./syouhizei_002.shを入力

###########################################################################
# 処理するファイルの設定
Meisai_File1="消費税内訳明細集計用.csv"
#★消費税内訳明細集計用.csv は　EXCEL CSVI/O　で消費税内訳明細.csvについて「出力データ→アクティブ領域"C5"」,「オプション→ダブルクォート囲み」をしたもの

#フィールド
# "1収入／支出","2大分類","3中分類","4小分類","5収入区分コード","6収入区分名称","7税区分コード","8税区分名称","9消費税及び地方消費税率"
# "10地方消費税率","11税込金額","12消費税額","13税抜金額","14特定収入額","15伝票日付","16伝票発生源区分","17伝票区分","18伝票番号"
# "19明細番号","20摘要","21予算区分","22予算款コード","23予算款名称","24予算項コード","25予算項名称","26予算目コード","27予算目名称"
# "28予算節コード","29予算節名称","30予算細節コード","31予算細節名称","32予算明細コード","33予算明細名称"

# ディレクトリ
Directory="C:/Users/komori/Desktop/TMP/DATA_IC/"

###########################################################################
# 処理作業

# 1.課税、非課税、不課税支出データを目、節で並び替え、データ保存 

# タイトル行出力
#echo '"7税区分コード","8税区分名称","9消費税及び地方消費税率","10地方消費税率","11税込金額" ,"12消費税額", "13税抜金額","14特定収入額","15伝票日付","18伝票番号","20摘要","21予算区分","22予算款コード","26予算目コード","27予算目名称","28予算節コード","29予算節名称"' | nkf -s >tmp1.csv

# システムから出力された生データの漢字コードをUTF8変換→3行目～支出データのみを抽出して中間ファイル作成、標準出力は捨てる

cat $Directory$Meisai_File1 |nkf -w8 \
|gawk 'BEGIN { FPAT = "([^,]+)|(\"[^\"]+\")";OFS=","; }
      NR >3 
      {
	 if (($22 ~/001/) || ($22 ~/003/))
           print $7,$8,$9,$10,$11,$12,$13,$14,$15,$18,$20,$21,$22,$26,$27,$28,$29 > "tmp1.csv"; #リダイレクトの書き方でうまく動いた
}' > /dev/null

# tmp1.csvから集計作業を行う $〇はtmp1.csvの列番号となる

# 右記添字で配列を作る。$3-"9消費税及び地方消費税率"→sep[1],$4-"10地方消費税率"→sep[2],$1-"7税区分コード"→sep[3],$2-"8税区分名称"→sep[4],
# $12-"21予算区分"→sep[5],",$13-"22予算款コード"→sep[6],$14-"26予算目コード"→sep[7],$15-"27予算目名称"→sep[8],$16-"28予算節コード"→sep[9],
# $17-"29予算節名称"→sep[10]

# "$3,$4,$1,$2,$12,$13,$14,$15,$16,$17"

# 目別集計
# 税込金額の集計
cat tmp1.csv \
| gawk 'BEGIN { FPAT="([^,]+)|(\"[^\"]+\")";OFS=","; } 
        {
	  gsub("\"","",$5); #　数値計算をさせるために追加
	  a[$3,$4,$1,$2,$12,$13,$14,$15]+= $5;
        } 
	END { for (i in a){
		split(i,sep,SUBSEP)
		print sep[1],sep[2],sep[3],sep[4],sep[5],sep[6],sep[7],sep[8],
		a[ sep[1],sep[2],sep[3],sep[4],sep[5],sep[6],sep[7],sep[8]];
	      }
	}'| LANG=C sort -t "," -k 3,3 -k 6,6 -k 7,7 -k 8,8 > tmp2.csv

# 消費税額の集計
cat tmp1.csv \
| gawk 'BEGIN { FPAT="([^,]+)|(\"[^\"]+\")";OFS=","; } 
        {
	  gsub("\"","",$6);
	  b[$3,$4,$1,$2,$12,$13,$14,$15]+= $6;
        } 
	END { for (i in b){
		split(i,sep,SUBSEP)
		print sep[1],sep[2],sep[3],sep[4],sep[5],sep[6],sep[7],sep[8],
		b[ sep[1],sep[2],sep[3],sep[4],sep[5],sep[6],sep[7],sep[8]];
	      }
	}' | LANG=C sort -t "," -k 3,3 -k 6,6 -k 7,7 -k 8,8 > tmp3.csv

# 列方向に統合し、ファイルセーブ　税込金額、消費税とも同一添字の配列で集計するため、pasteが機能する
# cutは表示する項目を指定する tmp3のタイトル列を表示しない
# gawkは整形で1列挿入するため

paste -d , tmp2.csv tmp3.csv | cut -d "," -f 1,2,4,5,6,8,9,18 \
	|gawk 'BEGIN { FS=","; OFS=","; } { print $1,$2,$3,$4,$5,$6," ",$7,$8; } END { printf("\n") }  '| nkf -s > 科目別仮受消費税集計.csv


# 節別集計
# 税込金額の集計
cat tmp1.csv \
| gawk 'BEGIN { FPAT="([^,]+)|(\"[^\"]+\")"; OFS=","; } 
	{ 
	  gsub("\"","",$5);
	  a[$3,$4,$1,$2,$12,$13,$14,$15,$16,$17]+= $5;
  	} 
	END { for (i in a){
		split(i,sep,SUBSEP)
		print sep[1],sep[2],sep[3],sep[4],sep[5],sep[6],sep[7],sep[8],sep[9],sep[10],
		a[ sep[1],sep[2],sep[3],sep[4],sep[5],sep[6],sep[7],sep[8],sep[9],sep[10]];
	      }
	}'| LANG=C sort -t "," -k 3,3 -k 6,6 -k 7,7 -k 8,8 > tmp4.csv

# 消費税額の集計
cat tmp1.csv \
| gawk 'BEGIN { FPAT="([^,]+)|(\"[^\"]+\")"; OFS=","; } 
	{
	  gsub("\"","",$6);
          b[$3,$4,$1,$2,$12,$13,$14,$15,$16,$17]+= $6;
        } 
	END { for (i in b){
		split(i,sep,SUBSEP)
		print sep[1],sep[2],sep[3],sep[4],sep[5],sep[6],sep[7],sep[8],sep[9],sep[10],
		b[ sep[1],sep[2],sep[3],sep[4],sep[5],sep[6],sep[7],sep[8],sep[9],sep[10]];
              }
        }'| LANG=C sort -t "," -k 3,3 -k 6,6 -k 7,7 -k 8,8 > tmp5.csv

# 列方向に統合し、ファイルセーブ　税込金額、消費税とも同一添字の配列で集計するため、pasteが機能する
# cutは表示する項目を指定する

paste -d , tmp4.csv tmp5.csv | cut -d "," -f 1,2,4,5,6,8,10,11,22 | nkf -s >> 科目別仮受消費税集計.csv

# 一時ファイル削除
rm tmp*.csv

