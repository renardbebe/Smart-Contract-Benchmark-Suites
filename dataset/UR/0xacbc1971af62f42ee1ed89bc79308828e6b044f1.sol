 

pragma solidity ^0.5.2;

 

 
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

 

contract ERC20Interface {
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint256 _value) external;
}

contract Donations {
    using SafeMath for uint256;

    struct Knight
    {
        address ethAddress;
         
        uint256 equity;
    }

     
    mapping(string => Knight) knights;

     
    ERC20Interface constant horseToken = ERC20Interface(0x5B0751713b2527d7f002c0c4e2a37e1219610A6B);

     
    mapping(bool => uint256) private _toDistribute;
     
    mapping(bool => mapping(address => uint256)) private _balances;

     
    bool constant ETH = false;
    bool constant HORSE = true;
   
     
    constructor() public {
        knights["Safir"].equity = 27;
        knights["Safir"].ethAddress = 0x61F646be9E40F3C83Ae6C74e8b33f2708396D08C;
        knights["Lucan"].equity = 27;
        knights["Lucan"].ethAddress = 0x445D779acfE04C717cc6B0071D3713D7E405Dc99;
        knights["Lancelot"].equity = 27;
        knights["Lancelot"].ethAddress = 0x5873d3875274753f6680a2256aCb02F2e42Be1A6;
        knights["Hoel"].equity = 11;
        knights["Hoel"].ethAddress = 0x85a4F876A007649048a7D44470ec1d328895B8bb;
        knights["YwainTheBastard"].equity = 8;
        knights["YwainTheBastard"].ethAddress = 0x2AB8D865Db8b9455F4a77C70B9D8d953E314De28;
    }
    
     
    function () external payable {
        
    }
    
     
    function withdraw() external {
         
        _distribute(ETH);
        _distribute(HORSE);

         
        uint256 toSendHORSE = _balances[HORSE][msg.sender];
        uint256 toSendETH = _balances[ETH][msg.sender];

         
        if(toSendHORSE > 0) {
            _balances[HORSE][msg.sender] = 0;
            horseToken.transfer.gas(40000)(msg.sender,toSendHORSE);
        }

         
        if(toSendETH > 0) {
            _balances[ETH][msg.sender] = 0;
            msg.sender.transfer(toSendETH);
        }
    }
    
     
    function checkBalance() external view returns (uint256,uint256) {
        return (_balances[ETH][msg.sender],_balances[HORSE][msg.sender]);
    }

     
    function _update(bool isHorse) internal {
         
        uint256 balance = isHorse ? horseToken.balanceOf.gas(40000)(address(this)) : address(this).balance;
         
        if(balance > 0) {
            _toDistribute[isHorse] = balance
            .sub(_balances[isHorse][knights["Safir"].ethAddress])
            .sub(_balances[isHorse][knights["Lucan"].ethAddress])
            .sub(_balances[isHorse][knights["Lancelot"].ethAddress])
            .sub(_balances[isHorse][knights["YwainTheBastard"].ethAddress])
            .sub(_balances[isHorse][knights["Hoel"].ethAddress]);

             
        } else {
             
            _toDistribute[isHorse] = 0;
        }
    }
    
     
    function _distribute(bool isHorse) private {
         
         
        _update(isHorse);
         
        if(_toDistribute[isHorse] > 0) {
             
            uint256 parts = _toDistribute[isHorse].div(100);
             
            uint256 dueSafir = knights["Safir"].equity.mul(parts);
            uint256 dueLucan = knights["Lucan"].equity.mul(parts);
            uint256 dueLancelot = knights["Lancelot"].equity.mul(parts);
            uint256 dueYwainTheBastard = knights["YwainTheBastard"].equity.mul(parts);

             
            _balances[isHorse][knights["Safir"].ethAddress] = _balances[isHorse][knights["Safir"].ethAddress].add(dueSafir);
            _balances[isHorse][knights["Lucan"].ethAddress] = _balances[isHorse][knights["Lucan"].ethAddress].add(dueLucan);
            _balances[isHorse][knights["Lancelot"].ethAddress] = _balances[isHorse][knights["Lancelot"].ethAddress].add(dueLancelot);
            _balances[isHorse][knights["YwainTheBastard"].ethAddress] = _balances[isHorse][knights["YwainTheBastard"].ethAddress].add(dueYwainTheBastard);
             
            _balances[isHorse][knights["Hoel"].ethAddress] = _balances[isHorse][knights["Hoel"].ethAddress]
            .add(_toDistribute[isHorse] - dueSafir - dueLucan - dueLancelot - dueYwainTheBastard);
            
             
            _toDistribute[isHorse] = 0;
        }
    }
}