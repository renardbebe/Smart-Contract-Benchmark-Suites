 

pragma solidity ^0.4.24;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract SEcoinAbstract {function unlock() public;}

contract SECrowdsale {
        
        using SafeMath for uint256;
        
         
        address constant public SEcoin = 0xe45b7cd82ac0f3f6cfc9ecd165b79d6f87ed2875; 
        
         
        uint256 public startTime;
        uint256 public endTime;
          
         
        address public SEcoinWallet = 0x5C737AdC09a0cFA1C9b83E199971a677163ddd07; 
        address public SEcoinsetWallet = 0x52873e9191f21a26ddc8b65e5dddbac6b73b69e8; 
          
         
        uint256 public rate = 6000; 
        
         
        uint256 public weiRaised;
        uint256 public weiSold;
          
         
        address public SEcoinbuyer;
        address[] public SEcoinbuyerevent;
        uint256[] public SEcoinAmountsevent;
        uint256[] public SEcoinmonth;
        uint public firstbuy;
        uint SEcoinAmounts ;
        uint SEcoinAmountssend;

          
        mapping(address => uint) public icobuyer;
        mapping(address => uint) public icobuyer2;
          
        event TokenPurchase(address indexed purchaser, address indexed SEcoinbuyer, uint256 value, uint256 amount,uint SEcoinAmountssend);
        
      
    function () external payable {buyTokens(msg.sender);}
      
     
    function buyer(address SEcoinbuyer) internal{
          
        if(icobuyer[msg.sender]==0){
            icobuyer[msg.sender] = firstbuy;
            icobuyer2[msg.sender] = firstbuy;
            firstbuy++;
             
            SEcoinbuyerevent.push(SEcoinbuyer);
            SEcoinAmountsevent.push(SEcoinAmounts);
            SEcoinmonth.push(0);
    
        }else if(icobuyer[msg.sender]!=0){
            uint i = icobuyer2[msg.sender];
            SEcoinAmountsevent[i]=SEcoinAmountsevent[i]+SEcoinAmounts;
            icobuyer2[msg.sender]=icobuyer[msg.sender];}
        }
    
       
    function buyTokens(address SEcoinbuyer) public payable {
        require(SEcoinbuyer != address(0x0));
        require(selltime());
        require(msg.value>=1*1e16 && msg.value<=200*1e18);
        
         
        SEcoinAmounts = calculateObtainedSEcoin(msg.value);
        SEcoinAmountssend= calculateObtainedSEcoinsend(SEcoinAmounts);
        
         
        weiRaised = weiRaised.add(msg.value);
        weiSold = weiSold.add(SEcoinAmounts);
            
         
        require(ERC20Basic(SEcoin).transfer(SEcoinbuyer, SEcoinAmountssend));
            
         
        buyer(msg.sender);
        checkRate();
        forwardFunds();
            
         
        emit TokenPurchase(msg.sender, SEcoinbuyer, msg.value, SEcoinAmounts,SEcoinAmountssend);
    }
    
     
     
    function forwardFunds() internal {
        SEcoinWallet.transfer(msg.value);
    }
     
    function calculateObtainedSEcoin(uint256 amountEtherInWei) public view returns (uint256) {
        checkRate();
        return amountEtherInWei.mul(rate);
    }
    function calculateObtainedSEcoinsend (uint SEcoinAmounts)public view returns (uint){
        return SEcoinAmounts.div(10);
    }
    
     
    function selltime() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        return withinPeriod;
    }
    
     
    function hasEnded() public view returns (bool) {
        bool isEnd = now > endTime || weiRaised >= 299600000*1e18; 
        return isEnd;
    }
    
     
    function releaseSEcoin() public returns (bool) {
        require (msg.sender == SEcoinsetWallet);
        require (hasEnded() && startTime != 0);
        SEcoinAbstract(SEcoin).unlock();
    }
    
     
    function getunselltoken()public returns(bool){
        require (msg.sender == SEcoinsetWallet);
        require (hasEnded() && startTime != 0);
        uint256 remainedSEcoin = ERC20Basic(SEcoin).balanceOf(this)-weiSold;
        ERC20Basic(SEcoin).transfer(SEcoinWallet, remainedSEcoin);    
    }
    
     
    function getunselltokenB()public returns(bool){
        require (msg.sender == SEcoinsetWallet);
        require (hasEnded() && startTime != 0);
        uint256 remainedSEcoin = ERC20Basic(SEcoin).balanceOf(this);
        ERC20Basic(SEcoin).transfer(SEcoinWallet, remainedSEcoin);    
    }
    
     
    function start() public returns (bool) {
        require (msg.sender == SEcoinsetWallet);
        require (firstbuy==0);
        startTime = 1541001600; 
        endTime = 1543593599; 
        SEcoinbuyerevent.push(SEcoinbuyer);
        SEcoinAmountsevent.push(SEcoinAmounts);
        SEcoinmonth.push(0);
        firstbuy=1;
    }
    
     
    function changeSEcoinWallet(address _SEcoinsetWallet) public returns (bool) {
        require (msg.sender == SEcoinsetWallet);
        SEcoinsetWallet = _SEcoinsetWallet;
    }
      
     
    function checkRate() public returns (bool) {
        if (now>=startTime && now< 1541433599){
            rate = 6000; 
        }else if (now >= 1541433599 && now < 1542297599) {
            rate = 5000; 
        }else if (now >= 1542297599 && now < 1543161599) {
            rate = 4000; 
        }else if (now >= 1543161599)  {
            rate = 3500; 
        }
    }
      
     
    function getICOtoken(uint number)public returns(string){
        require(SEcoinbuyerevent[number] == msg.sender);
        require(now>=1543593600&&now<=1567267199);
        uint  _month;
        
         
        if(now>=1543593600 && now<=1546271999 && SEcoinmonth[number]==0){
            require(SEcoinmonth[number]==0);
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], SEcoinAmountsevent[number].div(10));
            SEcoinmonth[number]=1;
        }
        
         
        else if(now>=1546272000 && now<=1548950399 && SEcoinmonth[number]<=1){
            if(SEcoinmonth[number]==1){
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], SEcoinAmountsevent[number].div(10));
            SEcoinmonth[number]=2;
            }else if(SEcoinmonth[number]<1){
            _month = 2-SEcoinmonth[number];
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], (SEcoinAmountsevent[number].div(10))*_month); 
            SEcoinmonth[number]=2;}
        }
        
         
        else if(now>=1548950400 && now<=1551369599 && SEcoinmonth[number]<=2){
            if(SEcoinmonth[number]==2){
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], SEcoinAmountsevent[number].div(10));
            SEcoinmonth[number]=3;
            }else if(SEcoinmonth[number]<2){
            _month = 3-SEcoinmonth[number];
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], (SEcoinAmountsevent[number].div(10))*_month); 
            SEcoinmonth[number]=3;}
        }
        
         
        else if(now>=1551369600 && now<=1554047999 && SEcoinmonth[number]<=3){
            if(SEcoinmonth[number]==3){
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], SEcoinAmountsevent[number].div(10));
            SEcoinmonth[number]=4;
            }else if(SEcoinmonth[number]<3){
            _month = 4-SEcoinmonth[number];
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], (SEcoinAmountsevent[number].div(10))*_month); 
            SEcoinmonth[number]=4;}
        }
        
         
        else if(now>=1554048000 && now<=1556639999 && SEcoinmonth[number]<=4){
            if(SEcoinmonth[number]==4){
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], SEcoinAmountsevent[number].div(10));
            SEcoinmonth[number]=5;
            }else if(SEcoinmonth[number]<4){
            _month = 5-SEcoinmonth[number];
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], (SEcoinAmountsevent[number].div(10))*_month); 
           SEcoinmonth[number]=5;}
        }
        
         
        else if(now>=1556640000 && now<=1559318399 && SEcoinmonth[number]<=5){
            if(SEcoinmonth[number]==5){
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], SEcoinAmountsevent[number].div(10));
            SEcoinmonth[number]=6;
            }else if(SEcoinmonth[number]<5){
            _month = 6-SEcoinmonth[number];
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], (SEcoinAmountsevent[number].div(10))*_month); 
            SEcoinmonth[number]=6;}
        }
        
         
        else if(now>=1559318400 && now<=1561910399 && SEcoinmonth[number]<=6){
            if(SEcoinmonth[number]==6){
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], SEcoinAmountsevent[number].div(10));
            SEcoinmonth[number]=7;
            }else if(SEcoinmonth[number]<6){
            _month = 7-SEcoinmonth[number];
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], (SEcoinAmountsevent[number].div(10))*_month); 
            SEcoinmonth[number]=7;}
        }
        
         
        else if(now>=1561910400 && now<=1564588799 && SEcoinmonth[number]<=7){
            if(SEcoinmonth[number]==7){
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], SEcoinAmountsevent[number].div(10));
            SEcoinmonth[number]=8;
            }else if(SEcoinmonth[number]<7){
            _month = 8-SEcoinmonth[number];
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], (SEcoinAmountsevent[number].div(10))*_month); 
            SEcoinmonth[number]=8;}
        }
            
         
        else if(now>=1564588800 && now<=1567267199 && SEcoinmonth[number]<=8){
            if(SEcoinmonth[number]==8){
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], SEcoinAmountsevent[number].div(10));
            SEcoinmonth[number]=9;
            }else if(SEcoinmonth[number]<8){
            _month = 9-SEcoinmonth[number];
            ERC20Basic(SEcoin).transfer(SEcoinbuyerevent[number], (SEcoinAmountsevent[number].div(10))*_month); 
            SEcoinmonth[number]=9;}
        }    
        
         
        else if(now<1543593600 || now>1567267199 || SEcoinmonth[number]>=9){
            revert("Get all tokens or endtime");
        }
    }
}