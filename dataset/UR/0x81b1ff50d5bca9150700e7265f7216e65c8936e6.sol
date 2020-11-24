 

pragma solidity ^0.4.20;

 
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, 'Contract Paused!');
        _;
    }

    modifier whenPaused() {
        require(paused, 'Contract Active!');
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract EtherDrop is Pausable {

    uint constant PRICE_WEI = 2e16;

     
    uint constant FLAG_BLACKLIST = 1;

     
    uint constant QMAX = 1000;

     
    uint constant DMAX = 3;

     
    event NewDropIn(address addr, uint round, uint place, uint value);

     
    event NewWinner(address addr, uint round, uint place, uint value, uint price);

    struct history {

         
        uint blacklist;

         
        uint size;

         
        uint[] rounds;

         
        uint[] places;

         
        uint[] values;

         
        uint[] prices;
    }

     
    address[] private _queue;

     
    address[] private _winners;

     
    bytes32[] private _wincomma;

     
    bytes32[] private _wincommb;

     
    uint[] private _positions;

     
    uint[] private _blocks;

     
    uint public _round;

     
    uint public _counter;

     
    uint private _collectibles = 0;

     
    mapping(address => history) private _history;

     
    function currentRound() public view returns (uint round, uint counter, uint round_users, uint price) {
        return (_round, _counter, QMAX, PRICE_WEI);
    }

     
    function roundStats(uint index) public view returns (uint round, address winner, uint position, uint block_no) {
        return (index, _winners[index], _positions[index], _blocks[index]);
    }

     
    function userRounds(address user) public view returns (uint) {
        return _history[user].size;
    }

     
    function userRound(address user, uint index) public view returns (uint round, uint place, uint value, uint price) {
        history memory h = _history[user];
        return (h.rounds[index], h.places[index], h.values[index], h.prices[index]);
    }

     
    function() public payable whenNotPaused {
         
        require(msg.value >= PRICE_WEI, 'Insufficient Ether');

         
        if (_counter == QMAX) {

            uint r = DMAX;

            uint winpos = 0;

            _blocks.push(block.number);

            bytes32 _a = blockhash(block.number - 1);

            for (uint i = 31; i >= 1; i--) {
                if (uint8(_a[i]) >= 48 && uint8(_a[i]) <= 57) {
                    winpos = 10 * winpos + (uint8(_a[i]) - 48);
                    if (--r == 0) break;
                }
            }

            _positions.push(winpos);

             
            uint _reward = (QMAX * PRICE_WEI * 90) / 100;
            address _winner = _queue[winpos];

            _winners.push(_winner);
            _winner.transfer(_reward);

             
            history storage h = _history[_winner];
            h.prices[h.size - 1] = _reward;

             
            _wincomma.push(0x0);
            _wincommb.push(0x0);

             
            emit NewWinner(_winner, _round, winpos, h.values[h.size - 1], _reward);

             
            _collectibles += address(this).balance - _reward;

             
            _counter = 0;

             
            _round++;
        }

        h = _history[msg.sender];

         
        require(h.size == 0 || h.rounds[h.size - 1] != _round, 'Already In Round');

         
        h.size++;
        h.rounds.push(_round);
        h.places.push(_counter);
        h.values.push(msg.value);
        h.prices.push(0);

         
        if (_round == 0) {
            _queue.push(msg.sender);
        } else {
            _queue[_counter] = msg.sender;
        }

         
        emit NewDropIn(msg.sender, _round, _counter, msg.value);

         
        _counter++;
    }

     
    function comment(uint round, bytes32 a, bytes32 b) whenNotPaused public {

        address winner = _winners[round];

        require(winner == msg.sender, 'not a winner');
        require(_history[winner].blacklist != FLAG_BLACKLIST, 'blacklisted');

        _wincomma[round] = a;
        _wincommb[round] = b;
    }


     
    function blackList(address user) public onlyOwner {
        history storage h = _history[user];
        if (h.size > 0) {
            h.blacklist = FLAG_BLACKLIST;
        }
    }

     
    function userComment(uint round) whenNotPaused public view returns (address winner, bytes32 comma, bytes32 commb) {
        if (_history[_winners[round]].blacklist != FLAG_BLACKLIST) {
            return (_winners[round], _wincomma[round], _wincommb[round]);
        } else {
            return (0x0, 0x0, 0x0);
        }
    }

     
    function collect() public onlyOwner {
        owner.transfer(_collectibles);
    }
}