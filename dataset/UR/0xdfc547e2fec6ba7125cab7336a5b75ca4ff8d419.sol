 

pragma solidity 0.4.18;

 


 
contract ERC20 {
    function transfer(address _to, uint256 _value) public returns(bool);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

 

contract BetWEA {
 

 
    function BetWEA(address _tokenAddr, uint _limit) public {  
        tokenAddr = _tokenAddr;
        token = ERC20(_tokenAddr);
        limit = _limit;
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
    require(msg.sender == owner);
    _;}

     
    address public tokenAddr = 0x0;
    ERC20 token;
    address public owner;
    address[]  ParticipantesA;
    address[]  ParticipantesB;
    uint maximo;
    uint public winnerid;
    uint public minimowea = 10000;
    uint public limit;
    uint r = 0;  
    uint public precioether = 2000000000000000;  
    uint public discount = 60;  
    uint public percent = 95;  
    uint public Wp= precioether*discount/100;
    uint public preciowea = 10000;

 
    function ChooseA() public payable {
       require((r==0) && (now < limit));
       if(token.balanceOf(msg.sender) > minimowea){
           require(msg.value == Wp);
           ParticipantesA.push(msg.sender);
       } else {
          require(msg.value == precioether);
          ParticipantesA.push(msg.sender);
       }
    }

    function ChooseB() public payable {
       require((r==0) && (now < limit));
       if(token.balanceOf(msg.sender) > minimowea){
           require(msg.value == Wp);
           ParticipantesB.push(msg.sender);
       } else {
          require(msg.value == precioether);
          ParticipantesB.push(msg.sender);
       }
    }

     
     function ChooseAwea() public {
        require((r==0) && (now < limit));
        require(token.transferFrom(msg.sender, this, preciowea));
        ParticipantesA.push(msg.sender);

    }

    function ChooseBwea() public {
        require((r==0) && (now < limit));
        require(token.transferFrom(msg.sender, this, preciowea));
        ParticipantesB.push(msg.sender);

    }

    function setWinner(uint Resultado) public onlyOwner {  
     uint  ethtransfer = this.balance*percent/100;
     require(r == 0);
        if(Resultado == 1){
            maximo = ParticipantesA.length;
            winnerid = rand(maximo);
            r = 1;
            token.transfer(ParticipantesA[winnerid], token.balanceOf(this));
            ParticipantesA[winnerid].transfer(ethtransfer);

        } else if(Resultado == 2) {
            maximo = ParticipantesB.length;
            winnerid = rand(maximo);
            r = 2;
            token.transfer(ParticipantesB[winnerid], token.balanceOf(this));
            ParticipantesB[winnerid].transfer(ethtransfer);

        } else { revert();}
    }


 
    function Clean() public onlyOwner {
    ParticipantesA.length = 0;
    ParticipantesB.length = 0;
    winnerid = 0;
    r = 0;
    }

    function setLimit(uint _limit) public onlyOwner {
        limit = _limit;
    }

    function setNEW(address _tokenAddr,
    uint _preciowea,
    uint _precioether,
    uint _discount,
    uint _minimowea) public onlyOwner {
        tokenAddr = _tokenAddr;
        precioether = _precioether;
        preciowea = _preciowea;
        discount = _discount;
        minimowea = _minimowea;

    }

    function sacarETH() public onlyOwner {
        owner.transfer(this.balance);
    }

    function sacarWEA() public onlyOwner {
        token.transfer(owner, token.balanceOf(this));
    }

 

    function getParticipantesA() view public returns(address[]) {  
        return ParticipantesA;
    }

    function getParticipantesB() view public returns(address[]) {  
        return ParticipantesB;
    }

    function getWinner() view public returns(address) {
        if(r == 1){
        return ParticipantesA[winnerid];
        } else if(r==2){
            return ParticipantesB[winnerid];
        } else { revert(); }
    }

 
    function() public payable {
    }

 
    uint256 constant private FACTOR =  115792089;
    function rand(uint max) constant private returns (uint256 result){
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(block.blockhash(lastBlockNumber));
        return uint256((uint256(hashVal) / factor)) % max;
    }
}