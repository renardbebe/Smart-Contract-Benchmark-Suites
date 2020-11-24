 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

pragma solidity ^0.4.21;

contract Payments {

  address public coOwner;
  mapping(address => uint256) public payments; 

  function Payments() public {
     
    coOwner = msg.sender;
  }

  modifier onlyCoOwner() {
    require(msg.sender == coOwner);
    _;
  }

  function transferCoOwnership(address _newCoOwner) public onlyCoOwner {
    require(_newCoOwner != address(0));
    coOwner = _newCoOwner;
  }  
  
  function PayWins(address _winner) public {
	 require (payments[_winner] > 0 && _winner!=address(0) && this.balance >= payments[_winner]);
	 _winner.transfer(payments[_winner]);
  }

}

contract Fifteen is Payments {
   
  mapping (uint8 => mapping (uint8 => mapping (uint8 => uint8))) public fifteenPuzzles;
  mapping (uint8 => address) public puzzleIdOwner;
  mapping (uint8 => uint256) public puzzleIdPrice;
  uint256 public jackpot = 0;
  
  function initNewGame() public onlyCoOwner payable {
      
	 require (msg.value>0);
	 require (jackpot == 0); 
	 jackpot = msg.value;
	 
	 uint8 row;
	 uint8 col;
	 uint8 num;
	 
	 for (uint8 puzzleId=1; puzzleId<=6; puzzleId++) {
		num=15;
		puzzleIdOwner[puzzleId] = address(this);
		puzzleIdPrice[puzzleId] = 0.001 ether;
		for (row=1; row<=4; row++) {
			for (col=1; col<=4; col++) {
				fifteenPuzzles[puzzleId][row][col]=num;
				num--;
			}
		}
	 }
	 
  } 

  function getPuzzle(uint8 _puzzleId) public constant returns(uint8[16] puzzleValues) {    
	 uint8 row;
	 uint8 col;
	 uint8 num = 0;
	 for (row=1; row<=4; row++) {
		for (col=1; col<=4; col++) {
			puzzleValues[num] = fifteenPuzzles[_puzzleId][row][col];
			num++;
		}
	 }	
  }
  
  function changePuzzle(uint8 _puzzleId, uint8 _row, uint8 _col, uint8 _torow, uint8 _tocol) public gameNotStopped {  
	 require (msg.sender == puzzleIdOwner[_puzzleId]);
	 require (fifteenPuzzles[_puzzleId][_torow][_tocol] == 0);  
	 require (_row >= 1 && _row <= 4 && _col >= 1 && _col <= 4 && _torow >= 1 && _torow <= 4 && _tocol >= 1 && _tocol <= 4);
	 require ((_row == _torow && (_col-_tocol == 1 || _tocol-_col == 1)) || (_col == _tocol && (_row-_torow == 1 || _torow-_row== 1)));
	 
	 fifteenPuzzles[_puzzleId][_torow][_tocol] = fifteenPuzzles[_puzzleId][_row][_col];
	 fifteenPuzzles[_puzzleId][_row][_col] = 0;
	 
	 if (fifteenPuzzles[_puzzleId][1][1] == 1 && 
	     fifteenPuzzles[_puzzleId][1][2] == 2 && 
		 fifteenPuzzles[_puzzleId][1][3] == 3 && 
		 fifteenPuzzles[_puzzleId][1][4] == 4) 
	 {  
		msg.sender.transfer(jackpot);
		jackpot = 0;  
	 }
  }
  
  function buyPuzzle(uint8 _puzzleId) public gameNotStopped payable {
  
    address puzzleOwner = puzzleIdOwner[_puzzleId];
    require(puzzleOwner != msg.sender && msg.sender != address(0));

    uint256 puzzlePrice = puzzleIdPrice[_puzzleId];
    require(msg.value >= puzzlePrice);
	
	 
	puzzleIdOwner[_puzzleId] = msg.sender;
	
	uint256 oldPrice = uint256(puzzlePrice/2);
	
	 
	puzzleIdPrice[_puzzleId] = uint256(puzzlePrice*2);	

	
	 
	uint256 profitFee = uint256(oldPrice/5); 
	
	uint256 oldOwnerPayment = uint256(oldPrice + profitFee);
	
	 
    jackpot += uint256(profitFee*3);
	
    if (puzzleOwner != address(this)) {
      puzzleOwner.transfer(oldOwnerPayment); 
	  coOwner.transfer(profitFee); 
    } else {
      coOwner.transfer(oldOwnerPayment+profitFee); 
	}

	 
    if (msg.value > puzzlePrice) { 
		msg.sender.transfer(msg.value - puzzlePrice);
	}
  }  
  
  modifier gameNotStopped() {
    require(jackpot > 0);
    _;
  }    
	
	
}