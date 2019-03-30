/*
 *  Source machine generated by GadToolsBox V2.0b
 *  which is (c) Copyright 1991-1993 Jaba Development
 *
 *  GUI Designed by : Andreas Dobloug
 */

#define GetString( g )      ((( struct StringInfo * )g->SpecialInfo )->Buffer  )
#define GetNumber( g )      ((( struct StringInfo * )g->SpecialInfo )->LongInt )

#define GD_Nodetype                            0
#define GD_Min_between_login                   1
#define GD_Max_login_time                      2
#define GD_Locked_baud_rate                    3
#define GD_CTS_RTS                             4
#define GD_Hangup_mode                         5
#define GD_Open_at_Startup                     6
#define GD_screenmode                          7
#define GD_node_type                           8
#define GD_get_font                            9
#define GD_font_name                           10
#define GD_get_hold_path                       11
#define GD_get_tmpdir_path                     12
#define GD_font_size                           13
#define GD_Holdpath                            14
#define GD_tmppath                             15
#define GD_Window_x                            16
#define GD_Window_y                            17
#define GD_Window_height                       18
#define GD_Window_width                        19
#define GD_Modem_Init                          20
#define GD_Modem_on_hook                       21
#define GD_Modem_off_hook                      22
#define GD_Modem_answer                        23
#define GD_Modem_dial                          24
#define GD_Modem_ring                          25
#define GD_Modem_connect                       26
#define GD_Modem_no_carrier                    27
#define GD_Modem_at_string                     28
#define GD_modem_ok_string                     29
#define GD_Minimum_baud                        30
#define GD_Connect_wait                        31
#define GD_Modem_machine_baud                  32
#define GD_Comm_port                           33
#define GD_Comm_port_name                      34
#define GD_publicscren                         35
#define GD_NoSleep                             36

#define GDX_Nodetype                           0
#define GDX_Min_between_login                  1
#define GDX_Max_login_time                     2
#define GDX_Locked_baud_rate                   3
#define GDX_CTS_RTS                            4
#define GDX_Hangup_mode                        5
#define GDX_Open_at_Startup                    6
#define GDX_screenmode                         7
#define GDX_node_type                          8
#define GDX_get_font                           9
#define GDX_font_name                          10
#define GDX_get_hold_path                      11
#define GDX_get_tmpdir_path                    12
#define GDX_font_size                          13
#define GDX_Holdpath                           14
#define GDX_tmppath                            15
#define GDX_Window_x                           16
#define GDX_Window_y                           17
#define GDX_Window_height                      18
#define GDX_Window_width                       19
#define GDX_Modem_Init                         20
#define GDX_Modem_on_hook                      21
#define GDX_Modem_off_hook                     22
#define GDX_Modem_answer                       23
#define GDX_Modem_dial                         24
#define GDX_Modem_ring                         25
#define GDX_Modem_connect                      26
#define GDX_Modem_no_carrier                   27
#define GDX_Modem_at_string                    28
#define GDX_modem_ok_string                    29
#define GDX_Minimum_baud                       30
#define GDX_Connect_wait                       31
#define GDX_Modem_machine_baud                 32
#define GDX_Comm_port                          33
#define GDX_Comm_port_name                     34
#define GDX_publicscren                        35
#define GDX_NoSleep                            36

#define GD_m20                                 0
#define GD_m21                                 1
#define GD_m22                                 2
#define GD_m23                                 3
#define GD_m24                                 4
#define GD_m1                                  5
#define GD_m2                                  6
#define GD_m3                                  7
#define GD_m4                                  8
#define GD_m5                                  9
#define GD_m6                                  10
#define GD_m7                                  11
#define GD_m8                                  12
#define GD_m9                                  13
#define GD_m10                                 14
#define GD_m11                                 15
#define GD_m12                                 16
#define GD_m13                                 17
#define GD_m14                                 18
#define GD_m15                                 19
#define GD_m16                                 20
#define GD_m17                                 21
#define GD_m18                                 22
#define GD_m19                                 23
#define GD_Max_time_read_gadgets               24

#define GDX_m20                                0
#define GDX_m21                                1
#define GDX_m22                                2
#define GDX_m23                                3
#define GDX_m24                                4
#define GDX_m1                                 5
#define GDX_m2                                 6
#define GDX_m3                                 7
#define GDX_m4                                 8
#define GDX_m5                                 9
#define GDX_m6                                 10
#define GDX_m7                                 11
#define GDX_m8                                 12
#define GDX_m9                                 13
#define GDX_m10                                14
#define GDX_m11                                15
#define GDX_m12                                16
#define GDX_m13                                17
#define GDX_m14                                18
#define GDX_m15                                19
#define GDX_m16                                20
#define GDX_m17                                21
#define GDX_m18                                22
#define GDX_m19                                23
#define GDX_Max_time_read_gadgets              24

#define GD_b20                                 0
#define GD_b21                                 1
#define GD_b22                                 2
#define GD_b23                                 3
#define GD_b24                                 4
#define GD_b1                                  5
#define GD_b2                                  6
#define GD_b3                                  7
#define GD_b4                                  8
#define GD_b5                                  9
#define GD_b6                                  10
#define GD_b7                                  11
#define GD_b8                                  12
#define GD_b9                                  13
#define GD_b10                                 14
#define GD_b11                                 15
#define GD_b12                                 16
#define GD_b13                                 17
#define GD_b14                                 18
#define GD_b15                                 19
#define GD_b16                                 20
#define GD_b17                                 21
#define GD_b18                                 22
#define GD_b19                                 23
#define GD_Min_time_read_gadgets               24

#define GDX_b20                                0
#define GDX_b21                                1
#define GDX_b22                                2
#define GDX_b23                                3
#define GDX_b24                                4
#define GDX_b1                                 5
#define GDX_b2                                 6
#define GDX_b3                                 7
#define GDX_b4                                 8
#define GDX_b5                                 9
#define GDX_b6                                 10
#define GDX_b7                                 11
#define GDX_b8                                 12
#define GDX_b9                                 13
#define GDX_b10                                14
#define GDX_b11                                15
#define GDX_b12                                16
#define GDX_b13                                17
#define GDX_b14                                18
#define GDX_b15                                19
#define GDX_b16                                20
#define GDX_b17                                21
#define GDX_b18                                22
#define GDX_b19                                23
#define GDX_Min_time_read_gadgets              24

#define Confignode_CNT 37
#define Max_login_CNT 25
#define Time_between_CNT 25

extern struct IntuitionBase *IntuitionBase;
extern struct Library       *GadToolsBase;



extern int SetupScreen( void );
extern void CloseDownScreen( void );
extern void ConfignodeRender( void );
extern int OpenConfignodeWindow( void );
extern void CloseConfignodeWindow( void );
extern void Max_loginRender( void );
extern int OpenMax_loginWindow( void );
extern void CloseMax_loginWindow( void );
extern void Time_betweenRender( void );
extern int OpenTime_betweenWindow( void );
extern void CloseTime_betweenWindow( void );