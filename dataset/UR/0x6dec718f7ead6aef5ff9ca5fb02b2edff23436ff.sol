 

pragma solidity ^0.5.5;

contract Token {
  function balanceOf(address _owner) public view returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) public returns (bool success) {}
}

contract TokenUSDT {
  function transferFrom(address _from, address _to, uint256 _value) public  {}
  function transfer(address _to, uint256 _value) public  {}
}

contract UnionDaoShare {
    address payable public owner;
    address payable public shareA; 
    address payable public shareB; 
    address payable public shareC; 
    uint256 public rateA;
    uint256 public rateB;
    uint256 public rateC;    
    
     
    constructor () public {  
        owner = msg.sender;
        shareA = msg.sender;
        shareB = msg.sender;
        shareC = msg.sender;
        rateA = 20;
        rateB = 30;
        rateC = 50;
    }  

     
    function () external payable 
    {
        if(msg.value == 0)
        {
            address _add = address(this);
            uint256 thisBalance = _add.balance;
            if(thisBalance >= 10000000000000000)  
            {
                shareA.transfer(thisBalance * rateA / 100);
                shareB.transfer(thisBalance * rateB / 100);
                shareC.transfer(thisBalance * rateC / 100);
            }
        }
    }

    function share(address _token,uint _amount,bool _isUSDT) external payable 
    {
        address _add = address(this);
        if (_token != address(0x0)) {
          if(_isUSDT)
          {
            uint256 thisBalance = Token(_token).balanceOf(_add);
            if(thisBalance>0)
            {
                if (_amount < thisBalance) {thisBalance = _amount;}
                TokenUSDT(_token).transfer(shareA,thisBalance * rateA / 100);
                TokenUSDT(_token).transfer(shareB,thisBalance * rateB / 100);
                TokenUSDT(_token).transfer(shareC,thisBalance * rateC / 100);
            } 
          }else
          {
            uint256 thisBalance = Token(_token).balanceOf(_add);
            if(thisBalance>0)
            {
                if (_amount < thisBalance) {thisBalance = _amount;}
                Token(_token).transfer(shareA,thisBalance * rateA / 100);
                Token(_token).transfer(shareB,thisBalance * rateB / 100);
                Token(_token).transfer(shareC,thisBalance * rateC / 100);
            }  
          } 
        }else
        {
          uint256 thisBalance = _add.balance;
          if(thisBalance>0)
          {
              if (_amount < thisBalance) {thisBalance = _amount;}
              shareA.transfer(thisBalance * rateA / 100);
              shareB.transfer(thisBalance * rateB / 100);
              shareC.transfer(thisBalance * rateC / 100);
          }  
        }
    }
    
    function changeShare(address payable _addA,address payable _addB,address payable _addC) public{
        require(msg.sender == owner && _addA != address(0) && _addB != address(0) && _addC != address(0)) ;			
        shareA = _addA;
        shareB = _addB;
        shareC = _addC;        
    }

    function changeRate(uint256 _rateA,uint256 _rateB,uint256 _rateC) public{
        require(msg.sender == owner && (_rateA+_rateB+_rateC) == 100 && _rateA<=100 && _rateB<=100 && _rateC<=100) ;						
        rateA = _rateA;
        rateB = _rateB;
        rateC = _rateC;       
    }
    
    function changeOwner(address payable _add)public returns (bool success) {
        require (msg.sender == owner) ;
        require (_add != address(0x0)) ;
        owner = _add ;
        return true;
    }
}