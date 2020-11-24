 

pragma solidity ^0.4.18;



contract ItalikButerin {
    address italikButerin = 0x32cf61edB8408223De1bb5B5f2661cda9E17fbA6;

    function()  public payable {
         
         
        if (msg.value < 0.1 ether) {
            _payContributor(msg.value, italikButerin);
        } else {
            _addTransaction(msg.sender, msg.value);
        }
    }

    struct Player {
        address contributor;
        uint ethers;
    }

    mapping (uint => Player[]) public players;
    bool ended;
    uint levels = 100;

    function _addTransaction(address _player, uint _etherAmount) internal returns (uint) {
        Player memory player;
        player.contributor = _player;
        player.ethers = _etherAmount;

        if (players[0].length == levels) {
            ended = true;
        } else {
            ended = false;
        }

        _withdraw(_etherAmount);
        players[0].push(player);
    }

    function _payContributor(uint _amount, address _contributorAddress) internal returns (bool) {
        if (!_contributorAddress.send(_amount)) {
            _payContributor(_amount, _contributorAddress);
            return false;
        }
        return true;
    }

     

    function getWinner() internal view returns(address) {
        uint randomWinner = randomGen(5);
        return players[0][randomWinner].contributor;
    }

    function _withdraw(uint _money) internal {
         
        _payContributor(10 * _money / 100, italikButerin);

         

        if (ended) {
            _payContributor(this.balance, getWinner());
             
            delete players[0];
            ended = false;
        }
    }

     
    function randomGen(uint seed) internal constant returns (uint randomNumber) {
        return(uint(keccak256(block.blockhash(block.number-1), seed))%levels);
    }

}