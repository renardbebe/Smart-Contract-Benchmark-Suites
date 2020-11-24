 

pragma solidity ^0.5.1;

 
 
contract SmartLotto {
    
	 
    using SafeMath for uint;
    
    uint private constant DAY_IN_SECONDS = 86400;
	
	 
	struct Member {
		address payable addr;						 
		uint ticket;								 
		uint8[5] numbers;                            
		uint8 matchNumbers;                          
		uint prize;                                  
	}
	
	
	 
	struct Game {
		uint datetime;								 
		uint8[5] win_numbers;						 
		uint membersCounter;						 
		uint totalFund;                              
		uint8 status;                                
		mapping(uint => Member) members;		     
	}
	
	mapping(uint => Game) public games;
	
	uint private CONTRACT_STARTED_DATE = 0;
	uint private constant TICKET_PRICE = 0.01 ether;
	uint private constant MAX_NUMBER = 36;						             
	
	uint private constant PERCENT_FUND_JACKPOT = 15;                         
	uint private constant PERCENT_FUND_4 = 35;                               
	uint private constant PERCENT_FUND_3 = 30;                               
    uint private constant PERCENT_FUND_2 = 20;                               
    
	uint public JACKPOT = 0;
	
	 
	uint public GAME_NUM = 0;
	uint private constant return_jackpot_period = 25 weeks;
	uint private start_jackpot_amount = 0;
	
	uint private constant PERCENT_FUND_PR = 12;                              
	uint private FUND_PR = 0;                                                

	 
	address private constant ADDRESS_SERVICE = 0x203bF6B46508eD917c085F50F194F36b0a62EB02;
	address payable private constant ADDRESS_START_JACKPOT = 0x531d3Bd0400Ae601f26B335EfbD787415Aa5CB81;
	address payable private constant ADDRESS_PR = 0xCD66911b6f38FaAF5BFeE427b3Ceb7D18Dd09F78;
	
	 
	event NewMember(uint _gamenum, uint _ticket, address _addr, uint8 _n1, uint8 _n2, uint8 _n3, uint8 _n4, uint8 _n5);
	event NewGame(uint _gamenum);
	event UpdateFund(uint _fund);
	event UpdateJackpot(uint _jackpot);
	event WinNumbers(uint _gamenum, uint8 _n1, uint8 _n2, uint8 _n3, uint8 _n4, uint8 _n5);
	event WinPrize(uint _gamenum, uint _ticket, uint _prize, uint8 _match);

	 
	function() external payable {
	    
         
		if(msg.sender == ADDRESS_START_JACKPOT) {
			processStartingJackpot();
		} else {
			if(msg.sender == ADDRESS_SERVICE) {
				startGame();
			} else {
				processUserTicket();
			}
		}
		return;
    }
	
	 
	 
	 
	function processStartingJackpot() private {
		 
		if(msg.value > 0) {
			JACKPOT += msg.value;
			start_jackpot_amount += msg.value;
			emit UpdateJackpot(JACKPOT);
		 
		} else {
			if(start_jackpot_amount > 0){
				_returnStartJackpot();
			}
		}
		return;
	}
	
	 
	function _returnStartJackpot() private { 
		
		if(JACKPOT > start_jackpot_amount * 2 || (now - CONTRACT_STARTED_DATE) > return_jackpot_period) {
			
			if(JACKPOT > start_jackpot_amount) {
				ADDRESS_START_JACKPOT.transfer(start_jackpot_amount);
				JACKPOT = JACKPOT - start_jackpot_amount;
				start_jackpot_amount = 0;
			} else {
				ADDRESS_START_JACKPOT.transfer(JACKPOT);
				start_jackpot_amount = 0;
				JACKPOT = 0;
			}
			emit UpdateJackpot(JACKPOT);
			
		} 
		return;
	}
	
	
	 
	 
	 
	function startGame() private {
	    
	    uint8 weekday = getWeekday(now);
		uint8 hour = getHour(now);
	    
		if(GAME_NUM == 0) {
		    GAME_NUM = 1;
		    games[GAME_NUM].datetime = now;
		    games[GAME_NUM].status = 1;
		    CONTRACT_STARTED_DATE = now;
		} else {
		    if(weekday == 7 && hour == 9) {

		        if(games[GAME_NUM].status == 1) {
		            processGame();
		        }

		    } else {
		        games[GAME_NUM].status = 1;
		    }
		    
		}
        return;
	}
	
	function processGame() private {
	    
	    uint8 mn = 0;
		uint winners5 = 0;
		uint winners4 = 0;
		uint winners3 = 0;
		uint winners2 = 0;

		uint fund4 = 0;
		uint fund3 = 0;
		uint fund2 = 0;
	    
	     
	    for(uint8 i = 0; i < 5; i++) {
	        games[GAME_NUM].win_numbers[i] = random(i);
	    }

	     
	    games[GAME_NUM].win_numbers = sortNumbers(games[GAME_NUM].win_numbers);
	    
	     
	    for(uint8 i = 0; i < 4; i++) {
	        for(uint8 j = i+1; j < 5; j++) {
	            if(games[GAME_NUM].win_numbers[i] == games[GAME_NUM].win_numbers[j]) {
	                games[GAME_NUM].win_numbers[j]++;
	            }
	        }
	    }
	    
	    uint8[5] memory win_numbers;
	    win_numbers = games[GAME_NUM].win_numbers;
	    emit WinNumbers(GAME_NUM, win_numbers[0], win_numbers[1], win_numbers[2], win_numbers[3], win_numbers[4]);
	    
	    if(games[GAME_NUM].membersCounter > 0) {
	    
	         
	        for(uint i = 1; i <= games[GAME_NUM].membersCounter; i++) {
	            
	            mn = findMatch(games[GAME_NUM].win_numbers, games[GAME_NUM].members[i].numbers);
				games[GAME_NUM].members[i].matchNumbers = mn;
				
				if(mn == 5) {
					winners5++;
				}
				if(mn == 4) {
					winners4++;
				}
				if(mn == 3) {
					winners3++;
				}
				if(mn == 2) {
					winners2++;
				}
				
	        }
	        
	         
	        JACKPOT = JACKPOT + games[GAME_NUM].totalFund * PERCENT_FUND_JACKPOT / 100;
			fund4 = games[GAME_NUM].totalFund * PERCENT_FUND_4 / 100;
			fund3 = games[GAME_NUM].totalFund * PERCENT_FUND_3 / 100;
			fund2 = games[GAME_NUM].totalFund * PERCENT_FUND_2 / 100;
			
			if(winners4 == 0) {
			    JACKPOT = JACKPOT + fund4;
			}
			if(winners3 == 0) {
			    JACKPOT = JACKPOT + fund3;
			}
			if(winners2 == 0) {
			    JACKPOT = JACKPOT + fund2;
			}
            
			for(uint i = 1; i <= games[GAME_NUM].membersCounter; i++) {
			    
			    if(games[GAME_NUM].members[i].matchNumbers == 5) {
			        games[GAME_NUM].members[i].prize = JACKPOT / winners5;
			        games[GAME_NUM].members[i].addr.transfer(games[GAME_NUM].members[i].prize);
			        emit WinPrize(GAME_NUM, games[GAME_NUM].members[i].ticket, games[GAME_NUM].members[i].prize, 5);
			    }
			    
			    if(games[GAME_NUM].members[i].matchNumbers == 4) {
			        games[GAME_NUM].members[i].prize = fund4 / winners4;
			        games[GAME_NUM].members[i].addr.transfer(games[GAME_NUM].members[i].prize);
			        emit WinPrize(GAME_NUM, games[GAME_NUM].members[i].ticket, games[GAME_NUM].members[i].prize, 4);
			    }
			    
			    if(games[GAME_NUM].members[i].matchNumbers == 3) {
			        games[GAME_NUM].members[i].prize = fund3 / winners3;
			        games[GAME_NUM].members[i].addr.transfer(games[GAME_NUM].members[i].prize);
			        emit WinPrize(GAME_NUM, games[GAME_NUM].members[i].ticket, games[GAME_NUM].members[i].prize, 3);
			    }
			    
			    if(games[GAME_NUM].members[i].matchNumbers == 2) {
			        games[GAME_NUM].members[i].prize = fund2 / winners2;
			        games[GAME_NUM].members[i].addr.transfer(games[GAME_NUM].members[i].prize);
			        emit WinPrize(GAME_NUM, games[GAME_NUM].members[i].ticket, games[GAME_NUM].members[i].prize, 2);
			    }
			    
			    if(games[GAME_NUM].members[i].matchNumbers == 1) {
			        emit WinPrize(GAME_NUM, games[GAME_NUM].members[i].ticket, games[GAME_NUM].members[i].prize, 1);
			    }
			    
			}
			
			 
			if(winners5 != 0) {
			    JACKPOT = 0;
			    start_jackpot_amount = 0;
			}
			
	    }
	    
	    emit UpdateJackpot(JACKPOT);
	    
	     
	    GAME_NUM++;
	    games[GAME_NUM].datetime = now;
	    games[GAME_NUM].status = 0;
	    emit NewGame(GAME_NUM);
	    
	     
	    ADDRESS_PR.transfer(FUND_PR);
	    FUND_PR = 0;
	    
	    return;

	}
	
	 
	function findMatch(uint8[5] memory arr1, uint8[5] memory arr2) private pure returns (uint8) {
	    
	    uint8 cnt = 0;
	    
	    for(uint8 i = 0; i < 5; i++) {
	        for(uint8 j = 0; j < 5; j++) {
	            if(arr1[i] == arr2[j]) {
	                cnt++;
	                break;
	            }
	        }
	    }
	    
	    return cnt;

	}
	
	 
	 
	 
	function processUserTicket() private {
		
		uint8 weekday = getWeekday(now);
		uint8 hour = getHour(now);
		
		if( GAME_NUM > 0 && (weekday != 7 || (weekday == 7 && (hour < 8 || hour > 11 ))) ) {

		    if(msg.value == TICKET_PRICE) {
			    createTicket();
		    } else {
			    if(msg.value < TICKET_PRICE) {
				    FUND_PR = FUND_PR + msg.value.mul(PERCENT_FUND_PR).div(100);
				    games[GAME_NUM].totalFund = games[GAME_NUM].totalFund + msg.value.mul(100 - PERCENT_FUND_PR).div(100);
				    emit UpdateFund(games[GAME_NUM].totalFund);
			    } else {
				    msg.sender.transfer(msg.value.sub(TICKET_PRICE));
				    createTicket();
			    }
		    }
		
		} else {
		     msg.sender.transfer(msg.value);
		}
		
	}
	
	function createTicket() private {
		
		bool err = false;
		uint8[5] memory numbers;
		
		 
		FUND_PR = FUND_PR + TICKET_PRICE.mul(PERCENT_FUND_PR).div(100);
		games[GAME_NUM].totalFund = games[GAME_NUM].totalFund + TICKET_PRICE.mul(100 - PERCENT_FUND_PR).div(100);
		emit UpdateFund(games[GAME_NUM].totalFund);
		
		 
		(err, numbers) = ParseCheckData();
		
		uint mbrCnt;

		 
		if(!err) {
		    numbers = sortNumbers(numbers);

		     
		    games[GAME_NUM].membersCounter++;
		    mbrCnt = games[GAME_NUM].membersCounter;

		     
		    games[GAME_NUM].members[mbrCnt].addr = msg.sender;
		    games[GAME_NUM].members[mbrCnt].ticket = mbrCnt;
		    games[GAME_NUM].members[mbrCnt].numbers = numbers;
		    games[GAME_NUM].members[mbrCnt].matchNumbers = 0;
		    
		    emit NewMember(GAME_NUM, mbrCnt, msg.sender, numbers[0], numbers[1], numbers[2], numbers[3], numbers[4]);
		    
		}

	}
	
	
	 
	function ParseCheckData() private view returns (bool, uint8[5] memory) {
	    
	    bool err = false;
	    uint8[5] memory numbers;
	    
	     
	    if(msg.data.length == 5) {
	        
	         
		    for(uint8 i = 0; i < msg.data.length; i++) {
		        numbers[i] = uint8(msg.data[i]);
		    }
		    
		     
		    for(uint8 i = 0; i < numbers.length; i++) {
		        if(numbers[i] < 1 || numbers[i] > MAX_NUMBER) {
		            err = true;
		            break;
		        }
		    }
		    
		     
		    if(!err) {
		    
		        for(uint8 i = 0; i < numbers.length-1; i++) {
		            for(uint8 j = i+1; j < numbers.length; j++) {
		                if(numbers[i] == numbers[j]) {
		                    err = true;
		                    break;
		                }
		            }
		            if(err) {
		                break;
		            }
		        }
		        
		    }
		    
	    } else {
	        err = true;
	    }

	    return (err, numbers);

	}
	
	 
	function sortNumbers(uint8[5] memory arrNumbers) private pure returns (uint8[5] memory) {
	    
	    uint8 temp;
	    
	    for(uint8 i = 0; i < arrNumbers.length - 1; i++) {
            for(uint j = 0; j < arrNumbers.length - i - 1; j++)
                if (arrNumbers[j] > arrNumbers[j + 1]) {
                    temp = arrNumbers[j];
                    arrNumbers[j] = arrNumbers[j + 1];
                    arrNumbers[j + 1] = temp;
                }    
	    }
        
        return arrNumbers;
        
	}
	
	 
    function getBalance() public view returns(uint) {
        uint balance = address(this).balance;
		return balance;
	}
	
	 
	function random(uint8 num) internal view returns (uint8) {
	    
        return uint8(uint(blockhash(block.number - 1 - num*2)) % MAX_NUMBER + 1);
        
    } 
    
    function getHour(uint timestamp) private pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }
    
    function getWeekday(uint timestamp) private pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }
	
	
	 
	
	 
	function getGameInfo(uint i) public view returns (uint, uint, uint, uint8, uint8, uint8, uint8, uint8, uint8) {
	    Game memory game = games[i];
	    return (game.datetime, game.totalFund, game.membersCounter, game.win_numbers[0], game.win_numbers[1], game.win_numbers[2], game.win_numbers[3], game.win_numbers[4], game.status);
	}
	
	 
	function getMemberInfo(uint i, uint j) public view returns (address, uint, uint8, uint8, uint8, uint8, uint8, uint8, uint) {
	    Member memory mbr = games[i].members[j];
	    return (mbr.addr, mbr.ticket, mbr.matchNumbers, mbr.numbers[0], mbr.numbers[1], mbr.numbers[2], mbr.numbers[3], mbr.numbers[4], mbr.prize);
	}

}

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}