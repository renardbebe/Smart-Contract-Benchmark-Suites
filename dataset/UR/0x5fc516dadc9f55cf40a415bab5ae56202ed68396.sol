 

pragma solidity ^0.4.21;

 

 
interface ERC20token {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
 
interface ERC721Token {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

contract ChiMarket {
    ERC20token ChiToken = ERC20token(0x71E1f8E809Dc8911FCAC95043bC94929a36505A5);
    address owner;
    uint256 market_halfspread;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function ChiMarket() public {
        owner = msg.sender;
    }

     
    function calcSELLoffer(uint256 chi_amount) public view returns(uint256){
        uint256 eth_balance = address(this).balance;
        uint256 chi_balance = ChiToken.balanceOf(this);
        uint256 eth_amount;
        require(eth_balance > 0 && chi_balance > 0);

        require(chi_balance + chi_amount >= chi_balance);  
        eth_amount = (chi_amount * eth_balance) / (chi_balance + chi_amount);
        require(1000 * eth_amount >= eth_amount);  
        eth_amount = ((1000 - market_halfspread) * eth_amount) / 1000;
        return eth_amount;
    }

     
     
     
     
    function calcBUYoffer(uint256 _chi_amount, uint256 _offset_eth) public view returns(uint256){
        require(address(this).balance > _offset_eth);  
        uint256 eth_balance = address(this).balance - _offset_eth;
        uint256 chi_balance = ChiToken.balanceOf(this);
        uint256 eth_amount;
        require(eth_balance > 0 && chi_balance > 0);
        require(chi_balance > _chi_amount);  
        
        require(chi_balance - _chi_amount <= chi_balance);  
        eth_amount = (_chi_amount * eth_balance) / (chi_balance - _chi_amount);
        require(1000 * eth_amount >= eth_amount);  
        eth_amount = (1000 * eth_amount) / (1000 - market_halfspread);
        return eth_amount;
    }

     
     
     
    function limitBuy(uint256 _chi_amount) public payable{
        require(_chi_amount > 0);
        uint256 eth_amount = calcBUYoffer(_chi_amount, msg.value);
        require(eth_amount <= msg.value);
        uint256 return_ETH_amount = msg.value - eth_amount;
        require(return_ETH_amount < msg.value);

        if(return_ETH_amount > 0){
            msg.sender.transfer(return_ETH_amount);  
        }
        require(ChiToken.transfer(msg.sender, _chi_amount));  
    }

     
     
     
     
    function limitSell(uint256 _chi_amount, uint256 _min_eth_amount) public {
        require(ChiToken.allowance(msg.sender, this) >= _chi_amount);
        uint256 eth_amount = calcSELLoffer(_chi_amount);
        require(eth_amount >= _min_eth_amount);
        require(eth_amount > 0);

        require(ChiToken.transferFrom(msg.sender, this, _chi_amount));
        msg.sender.transfer(eth_amount);
    }

     
     
    function moveERC20Tokens(address _tokenContract, address _to, uint _val) public onlyOwner {
        ERC20token token = ERC20token(_tokenContract);
        require(token.transfer(_to, _val));
    }

     
     
    function moveERC721Tokens(address _tokenContract, address _to, uint256 _tid) public onlyOwner {
        ERC721Token token = ERC721Token(_tokenContract);
        token.transferFrom(this, _to, _tid);
    }

     
    function moveEther(address _target, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance);
        _target.transfer(_amount);
    }

     
    function setSpread(uint256 _halfspread) public onlyOwner {
        require(_halfspread <= 50);
        market_halfspread = _halfspread;        
    }
 
     
     
    function depositBoth(uint256 _chi_amount) public payable onlyOwner {
        require(ChiToken.allowance(msg.sender, this) >= _chi_amount);
        require(ChiToken.transferFrom(msg.sender, this, _chi_amount));
    }

     
     
    function withdrawBoth(uint256 _chi_amount, uint256 _eth_amount) public onlyOwner {
        uint256 eth_balance = address(this).balance;
        uint256 chi_balance = ChiToken.balanceOf(this);
        require(_chi_amount <= chi_balance);
        require(_eth_amount <= eth_balance);
        
        msg.sender.transfer(_eth_amount);
        require(ChiToken.transfer(msg.sender, _chi_amount));
    }
 
     
    function setOwner(address _owner) public onlyOwner {
        owner = _owner;    
    }

     
    function() public payable{
    }
}