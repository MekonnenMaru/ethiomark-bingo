<?php
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }

        if (!isset($_SESSION['loggedin'])) {
            header("Location: ../config/logout.php");
            exit;
        }

        include_once '../config/Database.php';
        require_once '../config/CartelaResolver.php';
        require_once '../config/SupportCashierSchema.php';

        $db = Database::getInstance();
        $conn = $db->getConnection();

        $cashier_id = $_SESSION['cashier_id'] ?? '';
        support_cashier_ensure_defaults($conn, $cashier_id);
        $cartela_number = '';
        $round_number = 1;

        if ($cashier_id) {
            $query = "SELECT game.`round_number`, game.`cartela_number`, game.`iscompleted`
                    FROM `game` 
                    WHERE game.`cashier_id` = ?
                    ORDER BY game.`round_number` DESC
                    LIMIT 1";
            
            $stmt = $conn->prepare($query);
            $stmt->bind_param("s", $cashier_id);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($row = $result->fetch_assoc()) {
                $cartela_number = str_replace(' ', '', $row['cartela_number']);
                $round_number = ($row['iscompleted'] == 0) ? $row['round_number'] : $row['round_number'] + 1;
            }
            $stmt->close();
        }

        // Total cards: file (card_datas_new.json) when category exists there, else cartela table
        $count_cartela_amount = cartela_count_for_cashier($conn, $cashier_id);
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Ethiomark Bingo</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=1280, initial-scale=0.3, minimum-scale=0.1, maximum-scale=5.0, user-scalable=yes">
    
    <link rel="stylesheet" href="../bootstrap/css/style.css">
    <script src="../bootstrap/js/jquery.js"></script>
    <script src="../bootstrap/js/bootstrap.min.js"></script>
    <link rel="stylesheet" type="text/css" href="side-nav.css">
    <!-- Change the version number when you update the CSS -->
    <link rel="stylesheet" href="../bootstrap/css/register_new_game1.css?v=6.004">

    
    </head> 
<body>
        <script>
  if (localStorage.getItem('enableSupportCashier') === 'true') {
    window.location.replace('reg_new_game_support.php');
  }
</script>
        <script>
  document.addEventListener('contextmenu', function (e) {
    e.preventDefault();
    showAlert('Hello! You are using Ethiomark Bingo.', "success"); 
  });
</script>
    <div id="customAlert" class="custom-alert"></div>
    <div id="user-content">
        <?php include_once("side-nav.php"); ?>

        <div class="main-content">
            <p style="display: none;" id="cardnum"><?php echo $cartela_number; ?></p>
            <p style="display: none;" id="totalcard"><?php echo !empty($count_cartela_amount) ? $count_cartela_amount : 200; ?></p>
            
            <div class='content'>
                <div class="balls">
                    <div class="balls-line">
                        <h1 class="game-round-title">
                            Game Round <span id="register_new_game_round"><?php echo $round_number; ?></span>
                            <br>
                            <span id="previw_typed_number">[በ ኪቦርድ መመዝገብ ይችላሉ ⌨️⌨️]</span>
                            <button onclick="openHelpModal()" class="help-btn">❓ Help</button>
                            <label style="display: inline-flex; align-items: center; gap: 6px; margin-left: 12px; font-size: 16px; color: #d7e2ea; cursor: pointer; vertical-align: middle; white-space: nowrap;">
                                <input type="checkbox" id="enableSupportCashier" style="width: 16px; height: 16px; cursor: pointer;">
                                <span>Enable support cashier</span>
                            </label>
                        </h1>
                        
                        <!-- Help Modal -->
                        <div id="helpModal" class="help-modal">
                            <div class="help-modal-content">
                                <span onclick="closeHelpModal()" class="close-modal">&times;</span>
                                <h2>🆘 እርዳታ</h2>
                                <ul>
                                    <li>⌫ በ Backspace የተጻፉትን ቁጥሮች ያስወግዱ</li>
                                    <li>⏎ ኪቦርድ ላይ የሚፈልጉትን ቁጥር ከጻፉ በኋላ Enter ወይም space ሲጫኑ ቀጥታ ይመዘገባል።</li>
                                    <li>❗ ቁጥሩ ከተዘረዘሩት ካርድ ቁትሮች መካከል መሆን አለበት</li>
                                </ul>
                            </div>
                        </div>

                        <!-- Typing Helper -->
                        <div id="typingHelper" class="typing-helper">
                            <div><b>⌨️ Typing:</b> <span id="typingHelperNumber"></span></div>
                            <div id="typingHelperAction"></div>
                        </div>

                        <!-- View Toggle -->
                        <div class="view-toggle">
                            <button class="toggle-btn active" onclick="switchView('paginated')">Paginated View</button>
                            <button class="toggle-btn" onclick="switchView('scrollable')">Scrollable View</button>
                            <button id="toggleNumbersBtn" class="toggle-btn">
                                <span id="toggleIcon">👁️</span> Show
                            </button>
                        </div>
                        <hr class="section-divider">
                        <br>

                        
                        
                        <!-- Paginated View (Default) -->
                        <div id="paginatedView">
                            <div class="container" id="circledNumbers"></div>
                            <div class="next" id="pagination">
                                <button onclick="previousPage()">Previous</button>
                                <div id="pageButtons"></div>
                                <button onclick="nextPage()">Next</button>
                            </div>
                        </div>
                        
                        <!-- Scrollable View: same DOM as paginated (container only), no pagination bar -->
                        <div id="scrollableView">
                            <div class="container" id="numbersGrid"></div>
                        </div>
                        <div id="resizableContainer" hidden aria-hidden="true"></div>
                    </div>
                </div>
                
                <!-- Registration Card Section -->
                <div id="regcard">
                    <!-- Add this button near your view toggle buttons -->
                    
                    
                    <h1 class="selected-numbers-title" id="numbersTitle" hidden>እየተመዘገቡ ያሉ ካርድ ቁጥሮች!</h1>
                    <table id="tablereg" hidden></table>
                    <i id ="space"></i>
                    
                    <div class="form-controls">
                        <select required class="form-control" name="birr" id="birr">
                            <option value="10">በ 10ብር</option>
                            <option value="20">በ 20ብር</option>
                            <option value="30">በ 30ብር</option>
                            <option value="40">በ 40ብር</option>
                            <option value="50">በ 50ብር</option>
                            <option value="60">በ 60ብር</option>
                            <option value="70">በ 70ብር</option>
                            <option value="80">በ 80ብር</option>
                            <option value="100">በ 100ብር</option>
                            <option value="150">በ 150ብር</option>
                            <option value="200">በ 200ብር</option>
                            <option value="250">በ 250ብር</option>
                            <option value="300">በ 300ብር</option>
                            <option value="400">በ 400ብር</option>
                            <option value="500">በ 500ብር</option>
                            <option value="1000">በ 1000ብር</option>
                        </select>

                        <select required class="form-control" name="pattern" id="pattern">
                            <option value="1">any one line</option>
                            <option value="2">any two lines</option>
                            <option value="3">any three lines</option>
                            <option value="8">any vertical</option>
                            <option value="9">any horizontal</option>
                            <option value="7">Full</option>
                            <option value="5">T</option>
                            <option value="10">reverse T</option>
                            <option value="6">X</option>
                            <option value="4">L</option>
                            <option value="11">reverse L</option>
                            <option value="12">half above</option>
                            <option value="13">half below</option>
                        </select>

                        <div class="action-buttons">
                            <button class="login-btn play-btn" id="play">PLAY</button>
                            <button class="login-btn clear-btn" id="clearBtn">Clear</button>
                        </div>
                    </div>
                </div>
            </div>
             
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const supportCb = document.getElementById('enableSupportCashier');
            if (!supportCb) return;
            supportCb.checked = localStorage.getItem('enableSupportCashier') === 'true';
            supportCb.addEventListener('change', function() {
                localStorage.setItem('enableSupportCashier', this.checked ? 'true' : 'false');
                if (this.checked) {
                    window.location.href = 'reg_new_game_support.php';
                } else {
                    location.reload();
                }
            });
        });
    </script>
    <script>
        const _0x5f7bdc=_0x45c5;(function(_0xdd89bc,_0x4413ce){const _0x165af0=_0x45c5,_0xaad7cc=_0xdd89bc();while(!![]){try{const _0x311f8f=parseInt(_0x165af0(0xb6))/0x1*(-parseInt(_0x165af0(0xf7))/0x2)+parseInt(_0x165af0(0xcf))/0x3+-parseInt(_0x165af0(0x113))/0x4+parseInt(_0x165af0(0xe1))/0x5*(parseInt(_0x165af0(0x129))/0x6)+-parseInt(_0x165af0(0xb7))/0x7*(-parseInt(_0x165af0(0x149))/0x8)+-parseInt(_0x165af0(0x153))/0x9*(-parseInt(_0x165af0(0xca))/0xa)+parseInt(_0x165af0(0x14b))/0xb;if(_0x311f8f===_0x4413ce)break;else _0xaad7cc['push'](_0xaad7cc['shift']());}catch(_0x10b435){_0xaad7cc['push'](_0xaad7cc['shift']());}}}(_0x3c63,0x79bdd));let selectedNum=[],typedNumber='',currentView=localStorage['getItem'](_0x5f7bdc(0xec))||_0x5f7bdc(0x10a),currentPage=0x1;const numbersPerPage=0xc8;let totalNumbers=parseInt(document[_0x5f7bdc(0x100)](_0x5f7bdc(0x15e))[_0x5f7bdc(0x119)]),totalPages=Math[_0x5f7bdc(0x122)](totalNumbers/numbersPerPage);document[_0x5f7bdc(0xda)](_0x5f7bdc(0x15a),function(){initPaginatedView(),initScrollableView(),loadSavedSelections(),loadInitialCards(),setupEventListeners(),setupNumbersVisibilityToggle(),switchView(currentView);});function setupNumbersVisibilityToggle(){const _0x923ec1=_0x5f7bdc,_0x57243a=document[_0x923ec1(0x100)](_0x923ec1(0x10f)),_0x49bbb6=document['getElementById'](_0x923ec1(0x145)),_0x17b6eb=document[_0x923ec1(0x100)](_0x923ec1(0x12e)),_0x341b98=document['getElementById']('toggleIcon'),_0x4ffd8a=localStorage['getItem'](_0x923ec1(0xea))!==_0x923ec1(0x133);_0x5ba5d3(_0x4ffd8a),_0x57243a[_0x923ec1(0xda)](_0x923ec1(0xfa),function(){const _0x24bb50=_0x923ec1,_0x17d1b7=_0x49bbb6[_0x24bb50(0x154)]===![];_0x5ba5d3(!_0x17d1b7);});function _0x5ba5d3(_0x2d6e8f){const _0x4b9bdf=_0x923ec1;_0x49bbb6['hidden']=!_0x2d6e8f,_0x17b6eb[_0x4b9bdf(0x154)]=!_0x2d6e8f,_0x2d6e8f?document[_0x4b9bdf(0x100)]('space')[_0x4b9bdf(0xd9)]='':document[_0x4b9bdf(0x100)](_0x4b9bdf(0x15d))[_0x4b9bdf(0xd9)]=_0x4b9bdf(0x132),_0x341b98[_0x4b9bdf(0x124)]=_0x2d6e8f?'🙈':_0x4b9bdf(0xdb),_0x57243a[_0x4b9bdf(0xd9)]=_0x4b9bdf(0x10e)+(_0x2d6e8f?'🙈':_0x4b9bdf(0xdb))+_0x4b9bdf(0x160)+(_0x2d6e8f?'Hide':_0x4b9bdf(0x10c)),localStorage[_0x4b9bdf(0xee)](_0x4b9bdf(0xea),_0x2d6e8f),_0x2d6e8f&&selectedNum[_0x4b9bdf(0x144)]>0x0&&updateSelectedNumbers();}}function initPaginatedView(){showPage(0x1);}function initScrollableView(){const _0x2bb559=_0x5f7bdc,_0xf69cbd=localStorage['getItem'](_0x2bb559(0xc6)),_0xd69f30=localStorage[_0x2bb559(0xe3)](_0x2bb559(0xf8))||'60px';if(_0xf69cbd){const _0x2c80a6=JSON[_0x2bb559(0x14f)](_0xf69cbd),_0x124ad6=document[_0x2bb559(0x100)]('resizableContainer');_0x124ad6[_0x2bb559(0x14d)][_0x2bb559(0x12f)]=_0x2c80a6[_0x2bb559(0x12f)]||_0x2bb559(0x152),_0x124ad6['style']['height']=_0x2c80a6[_0x2bb559(0x127)]||_0x2bb559(0xef);}else{const _0x21333f=document[_0x2bb559(0x100)](_0x2bb559(0x15f));_0x21333f[_0x2bb559(0x14d)][_0x2bb559(0x12f)]=_0x2bb559(0x152),_0x21333f[_0x2bb559(0x14d)][_0x2bb559(0x127)]=_0x2bb559(0xef);}document[_0x2bb559(0xe4)][_0x2bb559(0x14d)][_0x2bb559(0xe5)](_0x2bb559(0x104),_0xd69f30),generateAllNumbers();let _0x28a980;const _0x11d536=document['getElementById'](_0x2bb559(0x15f));_0x11d536[_0x2bb559(0xda)](_0x2bb559(0x161),function(){clearTimeout(_0x28a980),_0x28a980=setTimeout(()=>{const _0xd122a5=_0x45c5;localStorage[_0xd122a5(0xee)](_0xd122a5(0xc6),JSON[_0xd122a5(0x13d)]({'width':this[_0xd122a5(0x14d)]['width'],'height':this[_0xd122a5(0x14d)]['height']}));},0x12c);});}function switchView(_0x302d96){const _0x5eea12=_0x5f7bdc;currentView=_0x302d96,localStorage[_0x5eea12(0xee)](_0x5eea12(0xec),_0x302d96),document[_0x5eea12(0x123)](_0x5eea12(0x11e))[_0x5eea12(0xf6)](_0x363298=>{const _0x2849d6=_0x5eea12;_0x363298[_0x2849d6(0xd5)][_0x2849d6(0x125)](_0x2849d6(0xcb));}),document[_0x5eea12(0xd0)](_0x5eea12(0xd8)+_0x302d96+'\x27)\x22]')['classList']['add'](_0x5eea12(0xcb)),document[_0x5eea12(0x100)](_0x5eea12(0x139))[_0x5eea12(0x14d)][_0x5eea12(0xb9)]=_0x302d96==='paginated'?_0x5eea12(0xd2):_0x5eea12(0xbf),document[_0x5eea12(0x100)](_0x5eea12(0xc5))[_0x5eea12(0x14d)][_0x5eea12(0xb9)]=_0x302d96===_0x5eea12(0x147)?_0x5eea12(0xd2):_0x5eea12(0xbf),document[_0x5eea12(0x100)](_0x5eea12(0xcd))['style'][_0x5eea12(0xb9)]=_0x302d96===_0x5eea12(0x10a)&&totalPages>0x1?_0x5eea12(0x112):'none';}function showPage(_0x19f8b8){currentPage=_0x19f8b8;const _0x159acf=(_0x19f8b8-0x1)*numbersPerPage+0x1;generateNumbers(_0x159acf),updatePagination();}function generateNumbers(_0x5f2ffc){const _0x50ecb2=_0x5f7bdc,_0xe8aa8b=document[_0x50ecb2(0x100)](_0x50ecb2(0x151));_0xe8aa8b[_0x50ecb2(0xd9)]='';for(let _0x2f030a=_0x5f2ffc;_0x2f030a<_0x5f2ffc+numbersPerPage&&_0x2f030a<=totalNumbers;_0x2f030a++){const _0xb19eac=document[_0x50ecb2(0xc4)]('div');_0xb19eac[_0x50ecb2(0xb5)]='box',_0xb19eac[_0x50ecb2(0x124)]=_0x2f030a,_0xb19eac[_0x50ecb2(0x12b)](_0x50ecb2(0x106),_0x2f030a),selectedNum[_0x50ecb2(0xc9)](_0x2f030a)&&_0xb19eac['classList'][_0x50ecb2(0xf5)]('snum'),_0xb19eac['onclick']=()=>selecting(_0x2f030a),_0xe8aa8b['appendChild'](_0xb19eac);}}function updatePagination(){const _0x4da0d7=_0x5f7bdc,_0x3391f6=document[_0x4da0d7(0x100)](_0x4da0d7(0x14c));_0x3391f6[_0x4da0d7(0xd9)]='';for(let _0x37b43e=0x1;_0x37b43e<=totalPages;_0x37b43e++){const _0xd101aa=document[_0x4da0d7(0xc4)](_0x4da0d7(0xba));_0xd101aa[_0x4da0d7(0x124)]=_0x37b43e,_0xd101aa[_0x4da0d7(0x11b)]=()=>showPage(_0x37b43e),_0x37b43e===currentPage&&(_0xd101aa[_0x4da0d7(0xdd)]=!![],_0xd101aa[_0x4da0d7(0xd5)][_0x4da0d7(0xf5)](_0x4da0d7(0x121))),_0x3391f6[_0x4da0d7(0xf3)](_0xd101aa);}}function _0x45c5(_0x5aa1a4,_0x433dfc){const _0x3c638b=_0x3c63();return _0x45c5=function(_0x45c552,_0x1dd64c){_0x45c552=_0x45c552-0xb4;let _0x4c53b2=_0x3c638b[_0x45c552];return _0x4c53b2;},_0x45c5(_0x5aa1a4,_0x433dfc);}function previousPage(){currentPage>0x1&&showPage(currentPage-0x1);}function nextPage(){currentPage<totalPages&&showPage(currentPage+0x1);}function generateAllNumbers(){const _0x5e6de7=_0x5f7bdc,_0x1bf6c5=document['getElementById']('numbersGrid');_0x1bf6c5[_0x5e6de7(0xd9)]='';for(let _0x422ff2=0x1;_0x422ff2<=totalNumbers;_0x422ff2++){const _0x4ba983=document[_0x5e6de7(0xc4)](_0x5e6de7(0xd3));_0x4ba983[_0x5e6de7(0xb5)]=_0x5e6de7(0x109),_0x4ba983[_0x5e6de7(0x124)]=_0x422ff2,_0x4ba983[_0x5e6de7(0x12b)](_0x5e6de7(0x106),_0x422ff2),selectedNum[_0x5e6de7(0xc9)](_0x422ff2)&&_0x4ba983[_0x5e6de7(0xd5)][_0x5e6de7(0xf5)](_0x5e6de7(0xc0)),_0x4ba983['onclick']=()=>selecting(_0x422ff2),_0x1bf6c5['appendChild'](_0x4ba983);}}function selecting(_0x11ffb4,_0x491951=![]){const _0x591fc4=_0x5f7bdc,_0xd48ea=selectedNum['indexOf'](_0x11ffb4);if(_0xd48ea===-0x1)selectedNum[_0x591fc4(0x159)](_0x11ffb4);else{if(_0x491951){if(document[_0x591fc4(0x100)](_0x591fc4(0xb4)))return;const _0x4163bd=document[_0x591fc4(0xc4)](_0x591fc4(0xd3));_0x4163bd['id']='retryModal',_0x4163bd[_0x591fc4(0x14d)]='\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20position:\x20fixed;\x20top:\x200;\x20left:\x200;\x20width:\x20100%;\x20height:\x20100%;\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20background:\x20rgba(0,0,0,0.5);\x20z-index:\x209999;\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20display:\x20flex;\x20justify-content:\x20center;\x20align-items:\x20center;\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20',_0x4163bd[_0x591fc4(0xd9)]=_0x591fc4(0x155)+_0x11ffb4+_0x591fc4(0x11f),document[_0x591fc4(0x157)][_0x591fc4(0xf3)](_0x4163bd);const _0x53f8be=document[_0x591fc4(0x100)](_0x591fc4(0xfb)),_0x170758=document[_0x591fc4(0x100)](_0x591fc4(0x110));function _0x9b26b7(){const _0xa9b146=_0x591fc4;_0x4163bd[_0xa9b146(0x125)](),document[_0xa9b146(0xb8)](_0xa9b146(0x14a),_0x5d7118);}_0x53f8be['onclick']=function(){const _0x24352e=_0x591fc4;_0x9b26b7(),selectedNum[_0x24352e(0x101)](_0xd48ea,0x1),updateNumberSelection(_0x11ffb4),updateSelectedNumbers(),showAlert('✅',_0x24352e(0xbc));},_0x170758[_0x591fc4(0x11b)]=function(){_0x9b26b7(),showAlert('❌\x20ማስገባት\x20ተሰርዟል።','danger');};function _0x5d7118(_0x17104b){const _0x2aae40=_0x591fc4;if(_0x17104b[_0x2aae40(0x12d)]===_0x2aae40(0xf1)||_0x17104b['key']==='\x20')_0x17104b[_0x2aae40(0xd1)](),_0x53f8be['click']();else _0x17104b['key']===_0x2aae40(0xe0)&&(_0x17104b['preventDefault'](),_0x170758[_0x2aae40(0xfa)]());}document['addEventListener'](_0x591fc4(0x14a),_0x5d7118);return;}else selectedNum[_0x591fc4(0x101)](_0xd48ea,0x1);}updateNumberSelection(_0x11ffb4),updateSelectedNumbers();}function updateNumberSelection(_0x1b9b64){const _0x58f8c8=_0x5f7bdc,_0x96974e=document['querySelector'](_0x58f8c8(0xd4)+_0x1b9b64+'\x22]');_0x96974e&&_0x96974e[_0x58f8c8(0xd5)][_0x58f8c8(0x135)](_0x58f8c8(0xc3),selectedNum[_0x58f8c8(0xc9)](_0x1b9b64));const _0x59907e=document[_0x58f8c8(0xd0)](_0x58f8c8(0x120)+_0x1b9b64+'\x22]');_0x59907e&&_0x59907e[_0x58f8c8(0xd5)]['toggle'](_0x58f8c8(0xc0),selectedNum['includes'](_0x1b9b64));}function updateSelectedNumbers(){const _0x5aab9b=_0x5f7bdc,_0x1702f1=document[_0x5aab9b(0x100)]('tablereg');_0x1702f1[_0x5aab9b(0xd9)]='';const _0x35282e=window[_0x5aab9b(0x14e)];let _0x47b7f0=0x6;if(_0x35282e<=0x2bc)_0x47b7f0=0x2;else{if(_0x35282e<=0x4b0)_0x47b7f0=0x3;else _0x35282e<=0x5dc&&(_0x47b7f0=0x5);}let _0x227db9=0x0;for(let _0x1b8edf=0x0;_0x1b8edf<selectedNum[_0x5aab9b(0x144)];_0x1b8edf++){if(_0x1b8edf%_0x47b7f0===0x0){const _0x38d035=_0x1702f1[_0x5aab9b(0x117)](_0x227db9);_0x227db9++;}const _0x381fb7=_0x1702f1[_0x5aab9b(0xf4)][_0x227db9-0x1]['insertCell'](_0x1b8edf%_0x47b7f0);_0x381fb7[_0x5aab9b(0xd9)]=selectedNum[_0x1b8edf],_0x381fb7[_0x5aab9b(0xb5)]='custom-cell';}document[_0x5aab9b(0x100)](_0x5aab9b(0x15b))[_0x5aab9b(0x14d)][_0x5aab9b(0xb9)]=selectedNum[_0x5aab9b(0x144)]>0x0?'block':'none';}function clearSelectedNumbers(){const _0x1767ea=_0x5f7bdc;selectedNum=[],document['querySelectorAll'](_0x1767ea(0x111))['forEach'](_0x31b72b=>{const _0x4252be=_0x1767ea;_0x31b72b['classList']['remove'](_0x4252be(0xc3),'selected');}),updateSelectedNumbers();}function loadSavedSelections(){const _0x1e2b1b=_0x5f7bdc,_0x4337d1=document[_0x1e2b1b(0x100)](_0x1e2b1b(0x108)),_0x363750=document[_0x1e2b1b(0x100)](_0x1e2b1b(0x116)),_0x5471da=localStorage[_0x1e2b1b(0xe3)]('selectedBirr'),_0xf67657=localStorage['getItem'](_0x1e2b1b(0x103));if(_0x5471da)_0x4337d1[_0x1e2b1b(0x114)]=_0x5471da;if(_0xf67657)_0x363750[_0x1e2b1b(0x114)]=_0xf67657;_0x4337d1['addEventListener'](_0x1e2b1b(0xe8),()=>localStorage[_0x1e2b1b(0xee)](_0x1e2b1b(0xf2),_0x4337d1['value'])),_0x363750['addEventListener'](_0x1e2b1b(0xe8),()=>localStorage[_0x1e2b1b(0xee)]('selectedPattern',_0x363750[_0x1e2b1b(0x114)]));}function loadInitialCards(){const _0x322be6=_0x5f7bdc,_0x579de9=document[_0x322be6(0x100)](_0x322be6(0x126))['innerText'][_0x322be6(0xbd)]();if(_0x579de9!==''){const _0x88ded3=_0x579de9['split'](',')[_0x322be6(0xc1)](Number);_0x88ded3[_0x322be6(0xf6)](_0x10a77a=>selecting(_0x10a77a));}}function _0x3c63(){const _0x3811cc=['pointer','length','numbersTitle','responseText','scrollable','removeClass','2585744jgwAFw','keydown','3425092GxZVyr','pageButtons','style','innerWidth','parse','cursor','circledNumbers','100%','9pdHRtB','hidden','\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20<div\x20style=\x22color:\x20green;\x20background:\x20#fff;\x20padding:\x2020px;\x20border-radius:\x2010px;\x20width:\x2090%;\x20max-width:\x20300px;\x20text-align:\x20center;\x20box-shadow:\x200\x204px\x2012px\x20rgba(0,0,0,0.3);\x22>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20<h3\x20style=\x22margin-bottom:\x2010px;\x20font-size:\x2025px;\x22>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20<i\x20style=\x22color:red;\x22>','openHelpModal','body','box-size-controls','push','DOMContentLoaded','regcard','online_status.php','space','totalcard','resizableContainer','</span>\x20','mouseup','retryModal','className','452444QLtwpm','14rdhGwS','removeEventListener','display','button','\x20<i\x20style=\x27color:white;\x27>❌</i>\x20የተሳሳተ\x20ቁጥር\x20ነው\x20የነኩ\x20እባክዎትን\x20ከ\x201\x20እስከ\x20','success','trim','cashier_id','none','selected','map','0.6','snum','createElement','scrollableView','bingoContainerSize','danger','Cashier\x20marked\x20as\x20offline\x20due\x20to\x20inactivity','includes','1354690vbPUvU','active','An\x20unexpected\x20error\x20occurred.','pagination','AJAX\x20Error:\x20','126525TVTLiy','querySelector','preventDefault','block','div','#paginatedView\x20[numb=\x22','classList','removeItem','message','.toggle-btn[onclick=\x22switchView(\x27','innerHTML','addEventListener','👁️','loggedin','disabled','../config/logout.php','...','Escape','4825ApCOYv','\x20ቁጥር\x20ብቻ\x20ይንኩ\x20!','getItem','documentElement','setProperty','opacity','closeHelpModal','change','register_new_game_round','numbersVisible','clearBtn','bingoView','#customAlert','setItem','400px','Backspace','Enter','selectedBirr','appendChild','rows','add','forEach','4JUaXra','bingoBoxSize','✅\x20Selected\x20with\x20Enter/Space','click','retryBtn','AJAX\x20error:','typingHelper','addClass','Successfully\x20logged\x20out!','getElementById','splice','not-allowed','selectedPattern','--box-size','slice','numb','status','birr','number-box','paginated','../config/DbFunction.php','Show','play','<span\x20id=\x22toggleIcon\x22>','toggleNumbersBtn','cancelBtn','.snum,\x20.selected','flex','135824yPgPUZ','value','location','pattern','insertRow','typingHelperAction','innerText','true','onclick','helpModal','JSON','.toggle-btn','</i>\x20&nbsp;&nbsp;የተመዘገበ\x20ቁጥር\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20</h3>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20<p\x20style=\x22margin-bottom:\x2020px;\x22>ቁጥሩ\x20ተመዝግቧል\x20ማጥፋት\x20ይፈልጋሉ?</p>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20<button\x20id=\x22retryBtn\x22\x20style=\x22font-size:\x2020px;\x20padding:\x208px\x2016px;\x20background-color:\x20#27ae60;\x20color:\x20white;\x20border:\x20none;\x20border-radius:\x204px;\x20margin-right:\x2010px;\x20cursor:\x20pointer;\x22>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20አዎ\x20እፈልጋለሁ\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20</button>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20<button\x20id=\x22cancelBtn\x22\x20style=\x22font-size:\x2020px;\x20padding:\x208px\x2016px;\x20background-color:\x20#e74c3c;\x20color:\x20white;\x20border:\x20none;\x20border-radius:\x204px;\x20cursor:\x20pointer;\x22>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20አይ\x20አልፈልግም\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20</button>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20</div>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20','#scrollableView\x20[numb=\x22','active-page','ceil','querySelectorAll','textContent','remove','cardnum','height','POST','1878ANWdgS','href','setAttribute','Request\x20timed\x20out','key','tablereg','width','PLAY','log','<i><br><br><br><br><br><br><br></i>','false','slide-out','toggle','show','\x20slide-in','beforeunload','paginatedView','Error\x20marking\x20as\x20offline\x20before\x20page\x20unload','❌\x20Deleted\x20last\x20digit','custom-alert-','stringify','typingHelperNumber','error','join','ajax','Please\x20fill\x20in\x20all\x20fields'];_0x3c63=function(){return _0x3811cc;};return _0x3c63();}function updateHelper(){const _0xb7226e=_0x5f7bdc;document[_0xb7226e(0x100)](_0xb7226e(0x13e))[_0xb7226e(0x119)]=typedNumber||_0xb7226e(0xdf),document['getElementById'](_0xb7226e(0xfd))[_0xb7226e(0x14d)][_0xb7226e(0xb9)]=_0xb7226e(0xd2);}function hideHelper(_0x3a9ccb=0xbb8){setTimeout(()=>{const _0x12ddde=_0x45c5;document[_0x12ddde(0x100)]('typingHelper')[_0x12ddde(0x14d)][_0x12ddde(0xb9)]=_0x12ddde(0xbf),document[_0x12ddde(0x100)]('typingHelperAction')['innerText']='';},_0x3a9ccb);}function setupEventListeners(){const _0x198b4f=_0x5f7bdc;document[_0x198b4f(0xda)]('keydown',function(_0x1fb5c0){const _0x5c9676=_0x198b4f;document['getElementById']('typingHelperAction')['innerText']='🖊️\x20Number\x20typed',updateHelper();if(_0x1fb5c0[_0x5c9676(0x12d)]>='0'&&_0x1fb5c0[_0x5c9676(0x12d)]<='9')typedNumber+=_0x1fb5c0[_0x5c9676(0x12d)],updateHelper();else{if(_0x1fb5c0['key']===_0x5c9676(0xf0))typedNumber=typedNumber[_0x5c9676(0x105)](0x0,-0x1),document[_0x5c9676(0x100)]('typingHelperAction')[_0x5c9676(0x119)]=_0x5c9676(0x13b),updateHelper();else{if(_0x1fb5c0[_0x5c9676(0x12d)]==='Enter'||_0x1fb5c0[_0x5c9676(0x12d)]==='\x20'){_0x1fb5c0[_0x5c9676(0xd1)]();if(typedNumber!==''){const _0x9a0ff5=parseInt(typedNumber);!isNaN(_0x9a0ff5)&&_0x9a0ff5>=0x1&&_0x9a0ff5<=totalNumbers?(selecting(_0x9a0ff5,!![]),document[_0x5c9676(0x100)](_0x5c9676(0x118))[_0x5c9676(0x119)]=_0x5c9676(0xf9)):showAlert(_0x9a0ff5+_0x5c9676(0xbb)+totalNumbers+_0x5c9676(0xe2),_0x5c9676(0xc7)),updateHelper(),hideHelper(),typedNumber='';}}}}}),document[_0x198b4f(0x100)](_0x198b4f(0xeb))[_0x198b4f(0xda)]('click',clearSelectedNumbers),document[_0x198b4f(0x100)](_0x198b4f(0x10d))[_0x198b4f(0xda)](_0x198b4f(0xfa),function(){const _0x32c9a6=_0x198b4f,_0x1c1929=this;_0x1c1929['disabled']=!![],_0x1c1929['innerText']='Saving...',_0x1c1929[_0x32c9a6(0x14d)][_0x32c9a6(0xe6)]=_0x32c9a6(0xc2),_0x1c1929[_0x32c9a6(0x14d)][_0x32c9a6(0x150)]=_0x32c9a6(0x102);const _0x543d38=localStorage[_0x32c9a6(0xe3)](_0x32c9a6(0xbe)),_0x55fd0a=selectedNum[_0x32c9a6(0x140)](',\x20'),_0x17131a=document[_0x32c9a6(0x100)]('birr')[_0x32c9a6(0x114)],_0xf6be8d=document[_0x32c9a6(0x100)](_0x32c9a6(0x116))[_0x32c9a6(0x114)],_0x103117=document[_0x32c9a6(0x100)](_0x32c9a6(0xe9))[_0x32c9a6(0xd9)];_0x17131a&&_0x55fd0a&&_0xf6be8d&&_0x543d38?$[_0x32c9a6(0x141)]({'type':_0x32c9a6(0x128),'url':_0x32c9a6(0x10b),'data':{'register_new_game_round':_0x103117,'selectedcard':_0x55fd0a,'price':_0x17131a,'pattern':_0xf6be8d,'cashier_id':_0x543d38},'dataType':_0x32c9a6(0x11d),'timeout':0x1388,'success':function(_0x1ac1d1){const _0x2cd417=_0x32c9a6;console['log'](_0x1ac1d1),_0x1ac1d1[_0x2cd417(0x107)]===_0x2cd417(0xbc)?(showAlert(_0x1ac1d1['message'],_0x1ac1d1['status']),setTimeout(()=>window['location'][_0x2cd417(0x12a)]='index.php',0x3e8)):showAlert(_0x1ac1d1[_0x2cd417(0xd7)],_0x2cd417(0xc7));},'error':function(_0x2f15b0,_0x4f9e70,_0x43b286){const _0x36be91=_0x32c9a6;console[_0x36be91(0x13f)](_0x36be91(0xce),_0x2f15b0[_0x36be91(0x146)]),_0x1c1929[_0x36be91(0xdd)]=![],_0x1c1929['innerText']=_0x36be91(0x130),_0x1c1929[_0x36be91(0x14d)][_0x36be91(0xe6)]='1',_0x1c1929[_0x36be91(0x14d)][_0x36be91(0x150)]=_0x36be91(0x143),_0x4f9e70==='timeout'?(console[_0x36be91(0x13f)](_0x36be91(0x12c)),showAlert('Request\x20timed\x20out.\x20Please\x20try\x20again.',_0x36be91(0xc7))):(console[_0x36be91(0x13f)](_0x36be91(0xfc),_0x4f9e70,_0x43b286),showAlert(_0x36be91(0xcc),_0x36be91(0xc7)));}}):showAlert(_0x32c9a6(0x142),_0x32c9a6(0xc7));}),window[_0x198b4f(0x156)]=function(){const _0x1ed696=_0x198b4f;document[_0x1ed696(0x100)](_0x1ed696(0x11c))[_0x1ed696(0x14d)][_0x1ed696(0xb9)]=_0x1ed696(0xd2);},window[_0x198b4f(0xe7)]=function(){const _0x38cf73=_0x198b4f;document['getElementById'](_0x38cf73(0x11c))[_0x38cf73(0x14d)]['display']=_0x38cf73(0xbf);},window[_0x198b4f(0x11b)]=function(_0x17bbff){const _0x1c80f6=_0x198b4f;_0x17bbff['target']===document[_0x1c80f6(0x100)](_0x1c80f6(0x11c))&&closeHelpModal();};}function showAlert(_0x8b7191,_0x3c7838){const _0x3bca35=_0x5f7bdc,_0x55ee74=$(_0x3bca35(0xed));_0x55ee74['html'](_0x8b7191)[_0x3bca35(0x148)]('custom-alert-success\x20custom-alert-danger\x20slide-out')[_0x3bca35(0xfe)](_0x3bca35(0x13c)+_0x3c7838+_0x3bca35(0x137))[_0x3bca35(0x136)](),setTimeout(()=>_0x55ee74[_0x3bca35(0x148)]('slide-in'),0x32),setTimeout(()=>{const _0x78c2c2=_0x3bca35;_0x55ee74['addClass'](_0x78c2c2(0x134)),setTimeout(()=>_0x55ee74['fadeOut'](),0x12c);},0xbb8);}localStorage[_0x5f7bdc(0xe3)]('loggedin')!==_0x5f7bdc(0x11a)&&(window['location'][_0x5f7bdc(0x12a)]=_0x5f7bdc(0xde));document[_0x5f7bdc(0x100)]('logoutbtn')[_0x5f7bdc(0xda)](_0x5f7bdc(0xfa),function(){const _0x399670=_0x5f7bdc;localStorage[_0x399670(0xd6)](_0x399670(0xdc)),localStorage[_0x399670(0xd6)]('cashier_id'),showAlert(_0x399670(0xff),'success'),setTimeout(()=>window[_0x399670(0x115)]['href']=_0x399670(0xde),0x3e8);});function adjustBoxSize(_0x69efa0){const _0x588956=_0x5f7bdc,_0x532b82=_0x69efa0+'px';document['documentElement'][_0x588956(0x14d)][_0x588956(0xe5)](_0x588956(0x104),_0x532b82),localStorage['setItem'](_0x588956(0xf8),_0x532b82),currentView===_0x588956(0x147)&&generateAllNumbers();}function addBoxSizeControls(){const _0xa1e0f=_0x5f7bdc,_0x4c321e=document[_0xa1e0f(0xc4)](_0xa1e0f(0xd3));_0x4c321e[_0xa1e0f(0xb5)]=_0xa1e0f(0x158),_0x4c321e[_0xa1e0f(0xd9)]='\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20<span>Box\x20Size:\x20</span>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20<button\x20onclick=\x22adjustBoxSize(40)\x22>Small</button>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20<button\x20onclick=\x22adjustBoxSize(60)\x22>Medium</button>\x0a\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20<button\x20onclick=\x22adjustBoxSize(80)\x22>Large</button>\x0a\x20\x20\x20\x20\x20\x20\x20\x20',document[_0xa1e0f(0xd0)]('.view-toggle')[_0xa1e0f(0xf3)](_0x4c321e);}addBoxSizeControls(),$(document)['ready'](function(){const _0x48e59c=_0x5f7bdc;let _0x32d8c4,_0x28b336;function _0x5ee30d(){const _0x15ddcf=_0x45c5;$[_0x15ddcf(0x141)]({'url':_0x15ddcf(0x15c),'method':'POST','data':{'heartbeat':!![]},'success':function(_0x2ba34a){const _0x19712c=_0x15ddcf;console[_0x19712c(0x131)]('Heartbeat\x20sent\x20successfully');},'error':function(){const _0x158549=_0x15ddcf;console[_0x158549(0x13f)]('Error\x20sending\x20heartbeat');}});}function _0x74ed11(){_0x28b336=setTimeout(function(){const _0x398061=_0x45c5;$[_0x398061(0x141)]({'url':_0x398061(0x15c),'method':_0x398061(0x128),'data':{'is_online':0x0},'success':function(_0x290b1a){const _0x13e409=_0x398061;console[_0x13e409(0x131)](_0x13e409(0xc8));},'error':function(){const _0x338048=_0x398061;console[_0x338048(0x13f)]('Error\x20marking\x20as\x20offline');}});},0x7530);}function _0x35660d(){clearTimeout(_0x28b336),_0x74ed11();}_0x32d8c4=setInterval(function(){_0x5ee30d(),_0x35660d();},0x7530),_0x5ee30d(),_0x74ed11(),$(window)['on'](_0x48e59c(0x138),function(){const _0x22ac8e=_0x48e59c;$[_0x22ac8e(0x141)]({'url':_0x22ac8e(0x15c),'method':_0x22ac8e(0x128),'data':{'is_online':0x0},'async':![],'success':function(_0x531613){const _0x2616d0=_0x22ac8e;console[_0x2616d0(0x131)]('Cashier\x20marked\x20as\x20offline\x20before\x20page\x20unload');},'error':function(){const _0x4d73d7=_0x22ac8e;console[_0x4d73d7(0x13f)](_0x4d73d7(0x13a));}});});});
    </script>
    <script>
        (function alignScrollableWithPaginatedView() {
            if (typeof generateAllNumbers !== 'function' || typeof initScrollableView !== 'function') {
                return;
            }

            function applyBoxSizeFromStorage() {
                const boxSize = localStorage.getItem('bingoBoxSize') || '60px';
                document.documentElement.style.setProperty('--box-size', boxSize);
            }

            initScrollableView = function () {
                applyBoxSizeFromStorage();
                generateAllNumbers();
            };

            generateAllNumbers = function () {
                const grid = document.getElementById('numbersGrid');
                if (!grid) {
                    return;
                }
                grid.innerHTML = '';
                grid.className = 'container';

                for (let i = 1; i <= totalNumbers; i++) {
                    const cell = document.createElement('div');
                    cell.className = 'box';
                    cell.textContent = i;
                    cell.setAttribute('numb', String(i));
                    if (selectedNum.includes(i)) {
                        cell.classList.add('snum');
                    }
                    cell.onclick = () => selecting(i);
                    grid.appendChild(cell);
                }
            };

            if (typeof updateNumberSelection === 'function') {
                const origUpdateNumberSelection = updateNumberSelection;
                updateNumberSelection = function (cardNum) {
                    origUpdateNumberSelection(cardNum);
                    const scrollEl = document.querySelector('#scrollableView [numb="' + cardNum + '"]');
                    if (scrollEl) {
                        scrollEl.classList.toggle('snum', selectedNum.includes(cardNum));
                        scrollEl.classList.remove('selected');
                    }
                };
            }
        })();
    </script>
    <script>
        $(document).ajaxSuccess(function(_event, xhr, settings) {
            const url = settings.url || '';
            const data = settings.data;
            const payload = typeof data === 'string' ? data : $.param(data || {});
            if (url.indexOf('DbFunction.php') === -1 || payload.indexOf('register_new_game_round') === -1) {
                return;
            }
            try {
                const resp = JSON.parse(xhr.responseText);
                if (resp.status === 'success' && resp.info) {
                    showAlert(resp.info, 'success');
                    if (resp.game_round) {
                        document.getElementById('register_new_game_round').innerHTML = resp.game_round;
                    }
                }
            } catch (e) {}
        });
    </script>
</body>
</html>