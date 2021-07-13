`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:17:20 11/27/2020 
// Design Name: 
// Module Name:    game_project 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module game_project(clk_1Mhz, rstn, in_9, in_0, in_c, in_d, in_a, in_b, in_e, in_f,
piezo, lcd_e, lcd_rs, lcd_rw, lcd_data, seg_com, seg_data, single_fnd);

input clk_1Mhz, rstn, in_9, in_0, in_c, in_d, in_a, in_b, in_e, in_f; // 클럭, 리셋, 버튼(노트 타깃용)
output piezo, lcd_e;
output reg lcd_rs, lcd_rw;
output reg [7:0] lcd_data; // 게임 메인 화면
output [3:0] seg_com;
output [7:0] seg_data; // 점수 표기
output [7:0] single_fnd; // 목숨 표기

// LCD 상태 관련 변수
parameter delay = 3'b000,
function_set = 3'b001,
entry_mode = 3'b010,
disp_onoff = 3'b011,
line1 = 3'b100,
line2 = 3'b101;
reg [2:0] state = delay; // LCD 상태 변수

// 피에조 관련 변수
reg piezo_buff = 1'b0, sound_out = 1'b0; // 피에조의 임시값과 소리 출력 유무
parameter C7 = 239, B6 = 253, A6 = 284, G6 = 319, F6 = 358, E6 = 379, D6s = 402, D6 = 426,
C6 = 478, B5 = 506, A5 = 568, G5 = 638, F5 = 716, E5 = 758, D5s = 804, D5 = 851, C5 = 956, G4 = 1276;

reg [10:0] sound_type = 11'b0, cnt_sound = 11'b0; // 음계 카운팅 최대값 저장용, 카운팅용
reg [11:0] cnt_song = 12'b1; // 노래 진행 정도

// 여기는 클럭 분주
wire clk_1khz; // 1MHz인 clk_1Mhz을 분주해서 얻은 1kHz 클럭
wire clk_game; // 게임 루프용 클럭, 일단 0.5초 주기
wire clk_song; // 노래 재생용 클럭, 0.05초 주기

divide_clk lcd(clk_1Mhz, rstn, 499, 0, 0, clk_1khz); // 1kHz로 분주
divide_clk game(clk_1khz, rstn, 249, state, line1, clk_game); // 게임루프에 쓸 2Hz 클럭 (25의 배수면서 500의 약수인 값 - 1이 카운팅 값: 1cd 클럭, 1줄 라인 카운팅과 맞아야하기 때문)
divide_clk song(clk_1khz, rstn, 24, state, line1, clk_song); // 노래에 쓸 0.05초 주기인 클럭

// 여기는 게임 세팅
reg [127:0] line1_str = "                ";
reg [127:0] line2_str = "                "; // 16글자짜리 문자열 화면 표시용

reg [31:0] random_seed = 32'b1; // 의사난수 시드 레지스터
reg [15:0] random = 16'b0; // 의사난수 레지스터

reg [7:0] game_note = " "; // 리듬게임 노트
reg [14:0] game_score = 15'b0; // 게임점수 (0 ~ 9999)
reg [3:0] game_live = 4'd9; // 잔여목숨 (0 ~ 9)

always @ (posedge clk_game or negedge rstn) begin // 게임루프로 이용
	if(~rstn) begin
		line1_str <= ":               ";
		line2_str <= ":               ";
		game_note <= " ";
		game_score <= 15'b0;
		game_live <= 4'd9;
	end
	else begin
		random_seed <= (random_seed * 1103515245 + 12345); // 난수 시드 생성 (의도적 오버플로 이용)
		random <= (random_seed / 65536) % 32768; // 난수 설정 (0~32767 범위)
		if(game_live == 0 || cnt_song >= 1195) begin // 목숨이 없거나 노래가 끝남
			line1_str <= "   2017440139   ";
			line2_str <= "   GAME ENDED   "; // 게임 종료 화면
		end
		else begin
			if(random < 1024)
				game_note <= "9";
			else if(random < 2048)
				game_note <= "0";
			else if(random < 3072)
				game_note <= "C";
			else if(random < 4096)
				game_note <= "D"; // 여기까지 왼손
			else if(random < 5120)
				game_note <= "A";
			else if(random < 6144)
				game_note <= "B";
			else if(random < 7168)
				game_note <= "E";
			else if(random < 8192)
				game_note <= "F"; // 여기는 오른손
			else
				game_note <= " ";
			// 127~0 -> 127~120: 고정, 119~112: 판정 구간, 111~0: 이동구간
			if(game_note == "9" || game_note == "0" || game_note == "C" || game_note == "D") begin // 왼손
				line1_str <= {":", line1_str[111:0], game_note};
				line2_str <= {":", line2_str[111:0], " "};
			end
			else if(game_note == "A" || game_note == "B" || game_note == "E" || game_note == "F") begin // 오른손
				line1_str <= {":", line1_str[111:0], " "};
				line2_str <= {":", line2_str[111:0], game_note};
			end
			else begin // 노트가 없는 경우
				line1_str <= {":", line1_str[111:0], " "};
				line2_str <= {":", line2_str[111:0], " "};
			end
			
			if(in_9 && line1_str[119:112] == "9") begin // 왼손의 점수, 타깃된 노트는 *로 표시
				game_score <= game_score + 70;
				line1_str <= {":*", line1_str[111:0]};
			end
			else if(in_0 && line1_str[119:112] == "0") begin
				game_score <= game_score + 70;
				line1_str <= {":*", line1_str[111:0]};
			end
			else if(in_c && line1_str[119:112] == "C") begin
				game_score <= game_score + 70;
				line1_str <= {":*", line1_str[111:0]};
			end
			else if(in_d && line1_str[119:112] == "D") begin
				game_score <= game_score + 70;
				line1_str <= {":*", line1_str[111:0]};
			end
			else if(line1_str[119:112] == "9" || line1_str[119:112] == "0" || line1_str[119:112] == "C" || line1_str[119:112] == "D") begin
				game_live <= game_live - 1; // 타깃 실패 -> 목숨 차감
			end
			
			if(in_a && line2_str[119:112] == "A") begin // 오른손의 점수, 타깃된 노트는 *로 표시
				game_score <= game_score + 70;
				line2_str <= {":*", line2_str[111:0]};
			end
			else if(in_b && line2_str[119:112] == "B") begin
				game_score <= game_score + 70;
				line2_str <= {":*", line2_str[111:0]};
			end
			else if(in_e && line2_str[119:112] == "E") begin
				game_score <= game_score + 70;
				line2_str <= {":*", line2_str[111:0]};
			end
			else if(in_f && line2_str[119:112] == "F") begin
				game_score <= game_score + 70;
				line2_str <= {":*", line2_str[111:0]};
			end
			else if(line2_str[119:112] == "A" || line2_str[119:112] == "B" || line2_str[119:112] == "E" || line2_str[119:112] == "F") begin
				game_live <= game_live - 1; // 타깃 실패 -> 목숨 차감
			end
			
			if(game_score > 9999)
				game_score <= 9999; // 점수 최대치 9999로 유지
		end
	end
end // 노래가 끝나거나 game_live가 0이 되면 게임 종료
score_segment score(clk_1khz, game_score, seg_com, seg_data);
fnd_decoder live(game_live, single_fnd);

// 여기는 노래 세팅
always @ (posedge clk_1Mhz) begin
	cnt_sound <= cnt_sound + 1;
	if(cnt_sound >= sound_type) begin
		cnt_sound <= 0;
		piezo_buff <=  ~piezo_buff;
	end
end

always @ (posedge clk_song or negedge rstn) begin
	if(~rstn) begin
		cnt_song <= 1;
		sound_out <= 0;
	end
	else begin
		if(game_live > 0 && cnt_song < 1195) begin  // 목숨이 남았거나 노래가 끝나지 않음
			cnt_song <= cnt_song + 1;
		end
		else begin
			cnt_song <= 1195; // 노래를 끝단계로 옮겨버림 -> 재생 방지
			sound_out <= 1'b0;
		end
		case(cnt_song)
			1: begin
				sound_out <= 1;
				sound_type <= G4;
			end
			4: begin
				sound_out <= 0;
			end
			5: begin
				sound_out <= 1;
				sound_type <= G4;
			end
			6: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			27: begin
				sound_out <= 0;
			end
			28: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			32: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			33: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			36: begin
				sound_out <= 1;
				sound_type <= C6;
			end
			39: begin
				sound_out <= 1;
				sound_type <= B5;
			end
			42: begin
				sound_out <= 1;
				sound_type <= A5;
			end
			45: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			52: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			56: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			57: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			64: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			68: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			69: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			76: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			80: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			81: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			
			102: begin
				sound_out <= 1;
				sound_type <= G4;
			end
			106: begin
				sound_out <= 0;
			end
			107: begin
				sound_out <= 1;
				sound_type <= G4;
			end
			108: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			125: begin
				sound_out <= 0;
			end
			126: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			130: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			131: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			134: begin
				sound_out <= 1;
				sound_type <= C6;
			end
			137: begin
				sound_out <= 1;
				sound_type <= B5;
			end
			140: begin
				sound_out <= 1;
				sound_type <= A5;
			end
			143: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			150: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			154: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			155: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			162: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			166: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			167: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			174: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			178: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			179: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			190: begin
				sound_out <= 0;
			end
			
			207: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			211: begin
				sound_out <= 0;
			end
			212: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			213: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			216: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			219: begin
				sound_out <= 0;
			end
			222: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			225: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			228: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			239: begin
				sound_out <= 0;
			end
			
			246: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			250: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			251: begin
				sound_out <= 1;
				sound_type <= D5s;
			end
			258: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			262: begin
				sound_out <= 1;
				sound_type <= D5s;
			end
			263: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			270: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			274: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			275: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			282: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			286: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			287: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			294: begin
				sound_out <= 0;
			end
			
			295: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			299: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			300: begin
				sound_out <= 1;
				sound_type <= D5s;
			end
			307: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			311: begin
				sound_out <= 1;
				sound_type <= D5s;
			end
			312: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			319: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			323: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			324: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			345: begin
				sound_out <= 1;
				sound_type <= C6;
			end
			352: begin
				sound_out <= 0;
			end
			
			353: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			357: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			358: begin
				sound_out <= 1;
				sound_type <= D5s;
			end
			365: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			369: begin
				sound_out <= 1;
				sound_type <= D5s;
			end
			370: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			377: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			381: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			382: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			389: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			393: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			394: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			401: begin
				sound_out <= 0;
			end
			
			402: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			406: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			407: begin
				sound_out <= 1;
				sound_type <= D5s;
			end
			414: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			418: begin
				sound_out <= 1;
				sound_type <= D5s;
			end
			419: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			426: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			430: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			431: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			452: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			459: begin
				sound_out <= 0;
			end
			
			460: begin
            sound_out <= 1;
            sound_type <= G5;
         end
         463: begin
            sound_out <= 0;
         end
         464: begin
            sound_out <= 1;
            sound_type <= G5;
         end
         465: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         486: begin
            sound_out <= 0;
         end
         487: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         491: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         492: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         495: begin
            sound_out <= 1;
            sound_type <= C7;
         end
         498: begin
            sound_out <= 1;
            sound_type <= B6;
         end
         501: begin
            sound_out <= 1;
            sound_type <= A6;
         end
         504: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         511: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         515: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         516: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         523: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         527: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         528: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         535: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         539: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         540: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         
         561: begin
            sound_out <= 1;
            sound_type <= G5;
         end
         565: begin
            sound_out <= 0;
         end
         566: begin
            sound_out <= 1;
            sound_type <= G5;
         end
         567: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         584: begin
            sound_out <= 0;
         end
         585: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         589: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         590: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         593: begin
            sound_out <= 1;
            sound_type <= C7;
         end
         596: begin
            sound_out <= 1;
            sound_type <= B6;
         end
         599: begin
            sound_out <= 1;
            sound_type <= A6;
         end
         602: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         609: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         613: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         614: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         621: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         625: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         626: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         633: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         637: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         638: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         649: begin
            sound_out <= 0;
         end
         
         666: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         670: begin
            sound_out <= 0;
         end
         671: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         672: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         675: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         678: begin
            sound_out <= 0;
         end
         681: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         684: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         687: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         698: begin
            sound_out <= 0;
         end
         
         705: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         709: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         710: begin
            sound_out <= 1;
            sound_type <= D6s;
         end
         717: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         721: begin
            sound_out <= 1;
            sound_type <= D6s;
         end
         722: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         729: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         733: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         734: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         741: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         745: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         746: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         753: begin
            sound_out <= 0;
         end
         
         754: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         758: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         759: begin
            sound_out <= 1;
            sound_type <= D6s;
         end
         766: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         770: begin
            sound_out <= 1;
            sound_type <= D6s;
         end
         771: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         778: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         782: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         783: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         804: begin
            sound_out <= 1;
            sound_type <= C7;
         end
         811: begin
            sound_out <= 0;
         end
         
         812: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         816: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         817: begin
            sound_out <= 1;
            sound_type <= D6s;
         end
         824: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         828: begin
            sound_out <= 1;
            sound_type <= D6s;
         end
         829: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         836: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         840: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         841: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         848: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         852: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         853: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         860: begin
            sound_out <= 0;
         end
         
         861: begin
            sound_out <= 1;
            sound_type <= C6;
         end
         865: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         866: begin
            sound_out <= 1;
            sound_type <= D6s;
         end
         873: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         877: begin
            sound_out <= 1;
            sound_type <= D6s;
         end
         878: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         885: begin
            sound_out <= 1;
            sound_type <= E6;
         end
         889: begin
            sound_out <= 1;
            sound_type <= F6;
         end
         890: begin
            sound_out <= 1;
            sound_type <= D6;
         end
         911: begin
            sound_out <= 1;
            sound_type <= G6;
         end
         918: begin
            sound_out <= 0;
         end
			
			919: begin
				sound_out <= 1;
				sound_type <= G4;
			end
			922: begin
				sound_out <= 0;
			end
			923: begin
				sound_out <= 1;
				sound_type <= G4;
			end
			924: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			945: begin
				sound_out <= 0;
			end
			946: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			950: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			951: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			954: begin
				sound_out <= 1;
				sound_type <= C6;
			end
			957: begin
				sound_out <= 1;
				sound_type <= B5;
			end
			960: begin
				sound_out <= 1;
				sound_type <= A5;
			end
			963: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			970: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			974: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			975: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			982: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			986: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			987: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			994: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			998: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			999: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			
			1020: begin
				sound_out <= 1;
				sound_type <= G4;
			end
			1024: begin
				sound_out <= 0;
			end
			1025: begin
				sound_out <= 1;
				sound_type <= G4;
			end
			1026: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1043: begin
				sound_out <= 0;
			end
			1044: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1048: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			1049: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			1052: begin
				sound_out <= 1;
				sound_type <= C6;
			end
			1055: begin
				sound_out <= 1;
				sound_type <= B5;
			end
			1058: begin
				sound_out <= 1;
				sound_type <= A5;
			end
			1061: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			1068: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			1072: begin
				sound_out <= 1;
				sound_type <= G5;
			end
			1073: begin
				sound_out <= 1;
				sound_type <= F5;
			end
			1080: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			1084: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			1085: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			1092: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			1096: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			1097: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1108: begin
				sound_out <= 0;
			end
			
			1125: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1129: begin
				sound_out <= 0;
			end
			1130: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1131: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			1134: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			1137: begin
				sound_out <= 0;
			end
			1140: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1143: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			1146: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1157: begin
				sound_out <= 0;
			end
			
			1158: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1162: begin
				sound_out <= 0;
			end
			1163: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1164: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			1167: begin
				sound_out <= 1;
				sound_type <= E5;
			end
			1170: begin
				sound_out <= 0;
			end
			1173: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1176: begin
				sound_out <= 1;
				sound_type <= D5;
			end
			1179: begin
				sound_out <= 1;
				sound_type <= C5;
			end
			1190: begin
				sound_out <= 0;
			end

			1191: begin
				sound_out <= 1;
				sound_type <= C6;
			end
			1195: begin
				sound_out <= 0;
			end
		endcase
	end
end
assign piezo = piezo_buff & sound_out; // sound_out이 0이 되면 출력도 없으므로 쉼표 등에 사용 가능

// 여기는 LCD 세팅
reg [9:0] cnt = 9'b0; // 0~700 범위 카운트
always @ (posedge clk_1khz or negedge rstn) begin // 상태 전이
	if(~rstn)
		state <= delay;
	else begin
		case(state)
			delay:
				if(cnt == 700)
					state <= function_set;
			function_set:
				if(cnt == 300)
					state <= disp_onoff;
			disp_onoff:
				if(cnt == 300)
					state <= entry_mode;
			entry_mode:
				if(cnt == 300) begin
					state <= line1;
				end
			line1:
				if(cnt == 24)
					state <= line2;
			line2:
				if(cnt == 24)
					state <= line1; // 상태 순환
			default:
				state <= delay;
		endcase
	end
end

always @ (posedge clk_1khz or negedge rstn) begin // 상태 전이 위한 카운트
	if(~rstn)
		cnt <= 9'b0;
	else begin
		case(state)
			delay:
				if(cnt >= 700)
					cnt <= 0;
				else
					cnt <= cnt + 1;
			function_set:
				if(cnt >= 300)
					cnt <= 0;
				else
					cnt <= cnt + 1;
			disp_onoff:
				if(cnt >= 300)
					cnt <= 0;
				else
					cnt <= cnt + 1;
			entry_mode:
				if(cnt >= 300)
					cnt <= 0;
				else
					cnt <= cnt + 1;
			line1:
				if(cnt >= 24)
					cnt <= 0;
				else
					cnt <= cnt + 1;
			line2:
				if(cnt >= 24)
					cnt <= 0;
				else
					cnt <= cnt + 1;
			default:
				cnt <= 9'b0;
		endcase
	end
end

always @ (posedge clk_1khz or negedge rstn) begin // LCD 세팅
	if(~rstn) begin
		lcd_rs <= 1'b1;
		lcd_rw <= 1'b1;
		lcd_data <= 8'b0;
	end
	else begin
		case(state)
			function_set: begin
				lcd_rs <= 1'b0;
				lcd_rw <= 1'b0;
				lcd_data <= 8'b00111100;
			end
			disp_onoff: begin
				lcd_rs <= 1'b0;
				lcd_rw <= 1'b0;
				lcd_data <= 8'b00001100;
			end
			entry_mode: begin
				lcd_rs <= 1'b0;
				lcd_rw <= 1'b0;
				lcd_data <= 8'b00000110;
			end
			line1: begin
				lcd_rw <= 1'b0;
				if(cnt == 0)
					{lcd_rs, lcd_data} <= 9'b010000000; // line1 어드레스 설정
				else begin
					lcd_rs <= 1'b1;
					case(cnt) // 각각 LCD 칸에 해당하는 문자 데이터
						1: lcd_data <= line1_str[127:120];
						2: lcd_data <= line1_str[119:112];
						3: lcd_data <= line1_str[111:104];
						4: lcd_data <= line1_str[103:96];
						5: lcd_data <= line1_str[95:88];
						6: lcd_data <= line1_str[87:80];
						7: lcd_data <= line1_str[79:72];
						8: lcd_data <= line1_str[71:64];
						9: lcd_data <= line1_str[63:56];
						10: lcd_data <= line1_str[55:48];
						11: lcd_data <= line1_str[47:40];
						12: lcd_data <= line1_str[39:32];
						13: lcd_data <= line1_str[31:24];
						14: lcd_data <= line1_str[23:16];
						15: lcd_data <= line1_str[15:8];
						16: lcd_data <= line1_str[7:0];
					endcase
				end
			end
			line2: begin
				lcd_rw <= 1'b0;
				if(cnt == 0)
					{lcd_rs, lcd_data} <= 9'b011000000; // line2 어드레스 설정
				else begin
					lcd_rs <= 1'b1;
					case(cnt) // 각각 LCD 칸에 해당하는 문자 데이터
						1: lcd_data <= line2_str[127:120];
						2: lcd_data <= line2_str[119:112];
						3: lcd_data <= line2_str[111:104];
						4: lcd_data <= line2_str[103:96];
						5: lcd_data <= line2_str[95:88];
						6: lcd_data <= line2_str[87:80];
						7: lcd_data <= line2_str[79:72];
						8: lcd_data <= line2_str[71:64];
						9: lcd_data <= line2_str[63:56];
						10: lcd_data <= line2_str[55:48];
						11: lcd_data <= line2_str[47:40];
						12: lcd_data <= line2_str[39:32];
						13: lcd_data <= line2_str[31:24];
						14: lcd_data <= line2_str[23:16];
						15: lcd_data <= line2_str[15:8];
						16: lcd_data <= line2_str[7:0];
					endcase
				end
			end
			default: begin
				lcd_rs <= 1'b1;
				lcd_rw <= 1'b1;
				lcd_data <= 8'b00000000;
			end
		endcase
	end
end
assign lcd_e = clk_1khz;

endmodule
