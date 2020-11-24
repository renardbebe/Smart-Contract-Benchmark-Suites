 

pragma solidity ^0.4.24;

 

contract ZTHReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}

contract ZTHInterface {
    function transfer(address _to, uint _value) public returns (bool);
    function approve(address spender, uint tokens) public returns (bool);
}

contract Zlots is ZTHReceivingContract {
    using SafeMath for uint;

    address private owner;
    address private bankroll;

     
    uint  totalSpins;
    uint  totalZTHWagered;

     
    uint contractBalance;

     
    bool    public gameActive;

    address private ZTHTKNADDR;
    address private ZTHBANKROLL;
    ZTHInterface private     ZTHTKN;

    mapping (uint => bool) validTokenBet;

     
    event HouseRetrievedTake(
        uint timeTaken,
        uint tokensWithdrawn
    );

     
    event TokensWagered(
        address _wagerer,
        uint _wagered
    );

    event LogResult(
        address _wagerer,
        uint _result,
        uint _profit,
        uint _wagered,
        uint _category,
        bool _win
    );

     
    event Loss(address _wagerer, uint _block);                   
    event ThreeMoonJackpot(address _wagerer, uint _block);       
    event TwoMoonPrize(address _wagerer, uint _block);           
    event ZTHJackpot(address _wagerer, uint _block);             
    event ThreeZSymbols(address _wagerer, uint _block);          
    event ThreeTSymbols(address _wagerer, uint _block);          
    event ThreeHSymbols(address _wagerer, uint _block);          
    event ThreeEtherIcons(address _wagerer, uint _block);        
    event ThreeGreenPyramids(address _wagerer, uint _block);     
    event ThreeGoldPyramids(address _wagerer, uint _block);      
    event ThreeWhitePyramids(address _wagerer, uint _block);     
    event OneMoonPrize(address _wagerer, uint _block);           
    event OneOfEachPyramidPrize(address _wagerer, uint _block);  
    event TwoZSymbols(address _wagerer, uint _block);            
    event TwoTSymbols(address _wagerer, uint _block);            
    event TwoHSymbols(address _wagerer, uint _block);            
    event TwoEtherIcons(address _wagerer, uint _block);          
    event TwoGreenPyramids(address _wagerer, uint _block);       
    event TwoGoldPyramids(address _wagerer, uint _block);        
    event TwoWhitePyramids(address _wagerer, uint _block);       
    
    event SpinConcluded(address _wagerer, uint _block);          

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBankroll {
        require(msg.sender == bankroll);
        _;
    }

    modifier onlyOwnerOrBankroll {
        require(msg.sender == owner || msg.sender == bankroll);
        _;
    }

     
    modifier gameIsActive {
        require(gameActive == true);
        _;
    }

    constructor(address ZethrAddress, address BankrollAddress) public {

         
        ZTHTKNADDR = ZethrAddress;
        ZTHBANKROLL = BankrollAddress;

         
        owner         = msg.sender;
        bankroll      = ZTHBANKROLL;

         
        ZTHTKN = ZTHInterface(ZTHTKNADDR);
        ZTHTKN.approve(ZTHBANKROLL, 2**256 - 1);
        
         
        ZTHTKN.approve(owner, 2**256 - 1);

         
        validTokenBet[1e18]  = true;
        validTokenBet[5e18]  = true;
        validTokenBet[10e18] = true;
        validTokenBet[25e18] = true;
        validTokenBet[50e18] = true;

        gameActive  = true;
    }

     
    function() public payable {  }

     
    struct TKN { address sender; uint value; }
    function tokenFallback(address _from, uint _value, bytes  ) public returns (bool){
        if (_from == bankroll) {
           
          contractBalance = contractBalance.add(_value);    
          return true;
        } else {
            TKN memory          _tkn;
            _tkn.sender       = _from;
            _tkn.value        = _value;
            _spinTokens(_tkn);
            return true;
        }
    }

    struct playerSpin {
        uint200 tokenValue;  
        uint56 blockn;       
    }

     
    mapping(address => playerSpin) public playerSpins;

     
    function _spinTokens(TKN _tkn) private {

        require(gameActive);
        require(_zthToken(msg.sender));
        require(validTokenBet[_tkn.value]);
        require(jackpotGuard(_tkn.value));

        require(_tkn.value < ((2 ** 200) - 1));    
        require(block.number < ((2 ** 56) - 1));   

        address _customerAddress = _tkn.sender;
        uint    _wagered         = _tkn.value;

        playerSpin memory spin = playerSpins[_tkn.sender];

        contractBalance = contractBalance.add(_wagered);

         
        require(block.number != spin.blockn);

         
        if (spin.blockn != 0) {
          _finishSpin(_tkn.sender);
        }

         
        spin.blockn = uint56(block.number);
        spin.tokenValue = uint200(_wagered);

         
        playerSpins[_tkn.sender] = spin;

         
        totalSpins += 1;

         
        totalZTHWagered += _wagered;

        emit TokensWagered(_customerAddress, _wagered);

    }

      
    function finishSpin() public
        gameIsActive
        returns (uint)
    {
      return _finishSpin(msg.sender);
    }

     
    function _finishSpin(address target)
        private returns (uint)
    {
        playerSpin memory spin = playerSpins[target];

        require(spin.tokenValue > 0);  
        require(spin.blockn != block.number);

        uint profit = 0;
        uint category = 0;

         
         
        uint result;
        if (block.number - spin.blockn > 255) {
          result = 999999;  
        } else {

           
           
          result = random(1000000, spin.blockn, target);
        }

        if (result > 476661) {
           
          emit Loss(target, spin.blockn);
          emit LogResult(target, result, profit, spin.tokenValue, category, false);
        } else {
            if (result < 1) {
                 
                profit = SafeMath.mul(spin.tokenValue, 500);
                category = 1;
                emit ThreeMoonJackpot(target, spin.blockn);
            } else 
                if (result < 298) {
                     
                    profit = SafeMath.mul(spin.tokenValue, 232);
                    category = 2;
                    emit TwoMoonPrize(target, spin.blockn);
            } else 
                if (result < 3127) {
                     
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 232), 10);
                    category = 3;
                    emit ZTHJackpot(target, spin.blockn);
                    
            } else 
                if (result < 5956) {
                     
                    profit = SafeMath.mul(spin.tokenValue, 25);
                    category = 4;
                    emit ThreeZSymbols(target, spin.blockn);
            } else 
                if (result < 8785) {
                     
                    profit = SafeMath.mul(spin.tokenValue, 25);
                    category = 5;
                    emit ThreeTSymbols(target, spin.blockn);
            } else 
                if (result < 11614) {
                     
                    profit = SafeMath.mul(spin.tokenValue, 25);
                    category = 6;
                    emit ThreeHSymbols(target, spin.blockn);
            } else 
                if (result < 14443) {
                     
                    profit = SafeMath.mul(spin.tokenValue, 50);
                    category = 7;
                    emit ThreeEtherIcons(target, spin.blockn);
            } else 
                if (result < 17272) {
                     
                    profit = SafeMath.mul(spin.tokenValue, 40);
                    category = 8;
                    emit ThreeGreenPyramids(target, spin.blockn);
            } else 
                if (result < 20101) {
                     
                    profit = SafeMath.mul(spin.tokenValue, 20);
                    category = 9;
                    emit ThreeGoldPyramids(target, spin.blockn);
            } else 
                if (result < 22929) {
                     
                    profit = SafeMath.mul(spin.tokenValue, 20);
                    category = 10;
                    emit ThreeWhitePyramids(target, spin.blockn);
            } else 
                if (result < 52332) {
                     
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 125),10);
                    category = 11;
                    emit OneMoonPrize(target, spin.blockn);
            } else 
                if (result < 120225) {
                     
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 15),10);
                    category = 12;
                    emit OneOfEachPyramidPrize(target, spin.blockn);
            } else 
                if (result < 171146) {
                     
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 232),100);
                    category = 13;
                    emit TwoZSymbols(target, spin.blockn);
            } else 
                if (result < 222067) {
                     
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 232),100);
                    category = 14;
                    emit TwoTSymbols(target, spin.blockn);
            } else 
                if (result < 272988) {
                     
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 232),100);
                    category = 15;
                    emit TwoHSymbols(target, spin.blockn);
            } else 
                if (result < 323909) {
                     
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 375),100);
                    category = 16;
                    emit TwoEtherIcons(target, spin.blockn);
            } else 
                if (result < 374830) {
                     
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 35),10);
                    category = 17;
                    emit TwoGreenPyramids(target, spin.blockn);
            } else 
                if (result < 425751) {
                     
                    profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 225),100);
                    category = 18;
                    emit TwoGoldPyramids(target, spin.blockn);
            } else {
                     
                    profit = SafeMath.mul(spin.tokenValue, 2);
                    category = 19;
                    emit TwoWhitePyramids(target, spin.blockn);
            }

            emit LogResult(target, result, profit, spin.tokenValue, category, true);
            contractBalance = contractBalance.sub(profit);
            ZTHTKN.transfer(target, profit);
          }
            
         
        playerSpins[target] = playerSpin(uint200(0), uint56(0));
        emit SpinConcluded(target, spin.blockn);
        return result;
    }   

     
     
     
     
    function jackpotGuard(uint _wager)
        private
        view
        returns (bool)
    {
        uint maxProfit = SafeMath.mul(_wager, 500);
        uint ninetyContractBalance = SafeMath.mul(SafeMath.div(contractBalance, 10), 9);
        return (maxProfit <= ninetyContractBalance);
    }

     
     
    function maxRandom(uint blockn, address entropy) private view returns (uint256 randomNumber) {
    return uint256(keccak256(
        abi.encodePacked(
        address(this),
        blockhash(blockn),
        entropy)
      ));
    }

     
    function random(uint256 upper, uint256 blockn, address entropy) internal view returns (uint256 randomNumber) {
    return maxRandom(blockn, entropy) % upper;
    }

     
    function balanceOf() public view returns (uint) {
        return contractBalance;
    }

    function addNewBetAmount(uint _tokenAmount)
        public
        onlyOwner
    {
        validTokenBet[_tokenAmount] = true;
    }

     
    function pauseGame() public onlyOwner {
        gameActive = false;
    }

     
    function resumeGame() public onlyOwner {
        gameActive = true;
    }

     
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

     
    function changeBankroll(address _newBankroll) public onlyOwner {
        bankroll = _newBankroll;
    }

    function divertDividendsToBankroll()
        public
        onlyOwner
    {
        bankroll.transfer(address(this).balance);
    }

     
    function _zthToken(address _tokenContract) private view returns (bool) {
       return _tokenContract == ZTHTKNADDR;
    }
}

 

 
library SafeMath {

     
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

     
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}