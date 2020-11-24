 

pragma solidity ^0.4.18;

 
contract Ownable {

    address public owner;
    address public secondOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier bothOwner() {
        require(msg.sender == owner || msg.sender == secondOwner);
        _;
    }

    function changeSecOwner(address targetAddress) public bothOwner {
        require(targetAddress != address(0));
        secondOwner = targetAddress;
    }

     
    function transferOwnership(address newOwner) public bothOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

interface token {
    function transfer(address receiver, uint amount) public returns (bool);
    function redeemToken(uint256 _mtcTokens, address _from) public;
}

contract addressKeeper is Ownable {
    address public tokenAddress;
    address public boardAddress;
    address public teamAddress;
    function setTokenAdd(address addr) onlyOwner public {
        tokenAddress = addr;
    }
    function setBoardAdd(address addr) onlyOwner public {
        boardAddress = addr;
    }
    function setTeamAdd(address addr) onlyOwner public {
        teamAddress = addr;
    }
}

contract MoatFund is addressKeeper {

     
     
     
    uint256 public mtcRate;  
    bool public mintBool;
    uint256 public minInvest;  

    uint256 public redeemRate;      
    bool public redeemBool;

    uint256 public ethRaised;        
    uint256 public ethRedeemed;      

     
    function startMint(uint256 _rate, bool canMint, uint256 _minWeiInvest) onlyOwner public {
        minInvest = _minWeiInvest;
        mtcRate = _rate;
        mintBool = canMint;
    }

     
    function startRedeem(uint256 _rate, bool canRedeem) onlyOwner public {
        redeemRate = _rate;
        redeemBool = canRedeem;
    }

    function () public payable {
        transferToken();
    }

     
    function transferToken() public payable {
        if (msg.sender != owner &&
            msg.sender != tokenAddress &&
            msg.sender != boardAddress) {
                require(mintBool);
                require(msg.value >= minInvest);

                uint256 MTCToken = (msg.value / mtcRate);
                uint256 teamToken = (MTCToken / 20);

                ethRaised += msg.value;

                token tokenTransfer = token(tokenAddress);
                tokenTransfer.transfer(msg.sender, MTCToken);
                tokenTransfer.transfer(teamAddress, teamToken);
        }
    }

     
    function redeem(uint256 _mtcTokens) public {
        if (msg.sender != owner) {
            require(redeemBool);

            token tokenBalance = token(tokenAddress);
            tokenBalance.redeemToken(_mtcTokens, msg.sender);

            uint256 weiVal = (_mtcTokens * redeemRate);
            ethRedeemed += weiVal;                                   
             
            msg.sender.transfer(weiVal);                             
        }
    }

    function sendETHtoBoard(uint _wei) onlyOwner public {
        boardAddress.transfer(_wei);
    }

    function collectERC20(address tokenAddress, uint256 amount) onlyOwner public {
        token tokenTransfer = token(tokenAddress);
        tokenTransfer.transfer(owner, amount);
    }

}