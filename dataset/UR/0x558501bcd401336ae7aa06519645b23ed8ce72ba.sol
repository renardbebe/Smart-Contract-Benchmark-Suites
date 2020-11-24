 

pragma solidity ^0.5.10;

 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract CanReclaimToken is Ownable {

   
  function reclaimToken(IERC20 token) external onlyOwner {
    address payable owner = address(uint160(owner()));

    if (address(token) == address(0)) {
      owner.transfer(address(this).balance);
      return;
    }
    uint256 balance = token.balanceOf(address(this));
    token.transfer(owner, balance);
  }

}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


contract AdminRole is Ownable {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor () internal {
        _addAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyOwner {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function removeAdmin(address account) public onlyOwner {
        _removeAdmin(account);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}


 
contract SNKGame is AdminRole, CanReclaimToken {
    using SafeMath for uint;

    address payable public dividendManagerAddress;

    struct Node {
        mapping (bool => uint) children;
        uint parent;
        bool side;
        uint height;
        uint count;
        uint dupes;
    }

    struct Game {
        mapping(uint => Node) bets;
        uint res;
        uint resPos;
        uint amount;

        mapping(uint => address[]) users;  
        mapping(uint => mapping(address => uint)) betUsers;  
        mapping(address => uint[]) userBets;  
        mapping(address => bool) executed;  

        uint winnersAmount;
        uint prizePool;
 
        uint lastLeftPos;
        uint lastRightPos;
        uint lastLeftValue;
        uint lastRightValue;
        bool allDone;
    }

    mapping (uint => Game) public games;

    uint public gameStep;
    uint public closeBetsTime;
    uint public gamesStart;
    uint public betValue;



    event NewBet(address indexed user, uint indexed game, uint bet, uint value);
    event ResultSet(uint indexed game, uint res, uint lastLeftValue, uint lastRightValue, uint amount);
    event PrizeTaken(address indexed user, uint game, uint amount);

    constructor(address payable _dividendManagerAddress, uint _betValue) public {
        require(_dividendManagerAddress != address(0));
        dividendManagerAddress = _dividendManagerAddress;

        gameStep = 10 minutes;
        closeBetsTime = 3 minutes;
        gamesStart = 1568332800;  
        betValue = _betValue;
    }


    function() external payable {
        revert();
    }


    function makeBet(uint _game, uint _bet) public payable {
        require(_bet > 0);
        require(betValue == 0 ? msg.value > 0 : msg.value == betValue);
        if (_game == 0) {
            _game = getCurrentGameId();
            if (now > getGameTime(_game) - closeBetsTime) {
                _game++;
            }
        } else {
            require(now < getGameTime(_game) - closeBetsTime);
        }

        _makeBet(games[_game], _bet);

        emit NewBet(msg.sender, _game, _bet, msg.value);
    }

    function setRes(uint _game, uint _res) onlyAdmin public {
        insertResult(_game, _res);
        setLastLeftRight(_game);
        shiftLeftRight(_game);
        setWinnersAmount(_game, 0, 0);
    }

    function insertResult(uint _game, uint _res) onlyAdmin public {
         
        _insertResult(games[_game], _res);
    }

    function setLastLeftRight(uint _game) onlyAdmin public {
        _setLastLeftRight(games[_game]);
    }

    function shiftLeftRight(uint _game) onlyAdmin public {
        _shiftLeftRight(games[_game]);
    }


    function setWinnersAmount(uint _game, uint _start, uint _stop) onlyAdmin public {
        _setWinnersAmount(games[_game], _start, _stop);
        if (games[_game].allDone) {
            emit ResultSet(_game, games[_game].res, games[_game].lastLeftValue, games[_game].lastRightValue, games[_game].amount);
        }
    }

    function isPrizeTaken(uint _game, address _user) public view returns (bool){
        return games[_game].executed[_user];
    }
    function isMyPrizeTaken(uint _game) public view returns (bool){
        return isPrizeTaken(_game, msg.sender);
    }


    function checkPrize(uint _game, address _user) public view returns (uint) {
        if (games[_game].executed[_user]) {
            return 0;
        }
        return _getPrizeAmount(games[_game], _user);
    }
    
    function checkMyPrize(uint _game) public view returns (uint) {
        return checkPrize(_game, msg.sender);
    }

    function getPrize(uint _game, address payable _user) public {
        uint amount = _getPrize(games[_game], _user);
        emit PrizeTaken(_user, _game, amount);
    }
    
    function getMyPrize(uint _game) public {
        getPrize(_game, msg.sender);
    }

    function getGameTime(uint _id) public view returns (uint) {
        return gamesStart + (gameStep * _id);
    }

    function setDividendManager(address payable _dividendManagerAddress) onlyOwner external  {
        require(_dividendManagerAddress != address(0));
        dividendManagerAddress = _dividendManagerAddress;
    }

    function getCurrentGameId() public view returns (uint) {
        return (now - gamesStart) / gameStep + 1;
    }

    function getNextGameId() external view returns (uint) {
        return (now - gamesStart) / gameStep + 2;
    }

    function getUserBetValues(uint _game, address _user) public view returns (uint[] memory values) {
         
         
         
         
        return games[_game].userBets[_user];
    }
    function getUserBetValues(uint _game) external view returns (uint[] memory values) {
        return getUserBetValues(_game, msg.sender);
    }

    function getUserBetAmounts(uint _game, address _user) public view returns (uint[] memory amounts) {
        amounts = new uint[](games[_game].userBets[_user].length);
        for (uint i = 0; i < games[_game].userBets[_user].length; i++) {
            amounts[i] = games[_game].betUsers[ games[_game].userBets[_user][i] ][_user];
        }
    }
    function getUserBetAmounts(uint _game) external view returns (uint[] memory values) {
        return getUserBetAmounts(_game, msg.sender);
    }


     

    function _makeBet(Game storage game, uint _bet) internal {
        if (game.betUsers[_bet][msg.sender] == 0) {
            _insert(game, _bet);
            game.users[_bet].push(msg.sender);
            game.userBets[msg.sender].push(_bet);
        }

        game.amount = game.amount.add(msg.value);
        game.betUsers[_bet][msg.sender] = game.betUsers[_bet][msg.sender].add(msg.value);
    }


    function _insertResult(Game storage game, uint _res) internal {
        _insert(game, _res);
        game.res = _res;
        game.resPos = _getPos(game, _res);
    }


    function _setLastLeftRight(Game storage game) internal returns (bool) {
        require(game.res > 0);

         
        if (game.bets[game.res].dupes > 0) {
            game.lastLeftPos = game.resPos;
            game.lastRightPos = game.resPos;
            game.lastLeftValue = game.res;
            game.lastRightValue = game.res;
            return true;
        }

        uint lastPos = _count(game) - 1;

        if (lastPos < 19) {  
             
            if (game.resPos == 0 || game.resPos == lastPos) {
                game.lastLeftPos = game.resPos == 0 ? 1 : lastPos - 1;
                game.lastRightPos = game.lastLeftPos;
            } else {
                uint leftBet =  _select_at(game, game.resPos - 1);
                uint rightBet = _select_at(game, game.resPos + 1);
                uint leftBetDif = game.res - leftBet;
                uint rightBetDif = rightBet - game.res;

                if (leftBetDif == rightBetDif) {
                    game.lastLeftPos = game.resPos - 1;
                    game.lastRightPos = game.resPos + 1;
                }

                if (leftBetDif > rightBetDif) {
                    game.lastLeftPos = game.resPos + 1;
                    game.lastRightPos = game.resPos + 1;
                }

                if (leftBetDif < rightBetDif) {
                     
                    game.lastLeftPos = game.resPos - 1;
                    game.lastRightPos = game.resPos - 1;
                }
            }
        } else {
            uint winnersCount = lastPos.add(1).mul(10).div(100);
            uint halfWinners = winnersCount.div(2);

            if (game.resPos < halfWinners) {
                game.lastLeftPos = 0;
                game.lastRightPos = game.lastLeftPos + winnersCount;
            } else {
                if (game.resPos + halfWinners > lastPos) {
                    game.lastRightPos = lastPos;
                    game.lastLeftPos = lastPos - winnersCount;
                } else {
                    game.lastLeftPos = game.resPos - halfWinners;
                    game.lastRightPos = game.lastLeftPos + winnersCount;
                }
            }
        }

        game.lastLeftValue = _select_at(game, game.lastLeftPos);
        game.lastRightValue = _select_at(game, game.lastRightPos);


         
        game.lastLeftPos = _getPos(game, game.lastLeftValue);
        game.lastRightPos = _getPos(game, game.lastRightValue); 

        return true;
    }


    function _shiftRight(Game storage game, uint leftBetDif, uint rightBetDif, uint _val, uint lastPos) internal {
        uint gleft = gasleft();
        uint gasused = 0;
        uint lastRightValue = game.lastRightValue;
        uint lastRightPos = game.lastRightPos;
        uint lastLeftValue = game.lastLeftValue;
        uint lastLeftPos = game.lastLeftPos;
        while (leftBetDif > rightBetDif) {

            lastRightValue = _val;
            lastRightPos = lastRightPos + 1 + game.bets[_val].dupes;

            lastLeftValue = _select_at(game, lastLeftValue + 1);
            lastLeftPos = _getPos(game, lastLeftValue);

            if (lastRightPos == lastPos) break;
            if (lastLeftPos >= game.resPos) break;

            _val = _select_at(game, lastRightPos + 1);
            leftBetDif = game.res - lastLeftValue;
            rightBetDif = _val - game.res;

            if (gasused == 0) {
                gasused = gleft - gasleft() + 100000;
            }
            if (gasleft() < gasused) break;
        }

        game.lastRightValue = lastRightValue;
        game.lastRightPos = lastRightPos;
        game.lastLeftValue = lastLeftValue;
        game.lastLeftPos = lastLeftPos;
    }


    function _shiftLeft(Game storage game, uint leftBetDif, uint rightBetDif, uint _val) internal {
        uint gleft = gasleft();
        uint gasused = 0;
        uint lastRightValue = game.lastRightValue;
        uint lastRightPos = game.lastRightPos;
        uint lastLeftValue = game.lastLeftValue;
        uint lastLeftPos = game.lastLeftPos;
        while (rightBetDif > leftBetDif) {
            lastLeftValue = _val;
            lastLeftPos = lastLeftPos - game.bets[lastLeftValue].dupes - 1;

            lastRightPos = lastRightPos - game.bets[lastRightValue].dupes - 1;
            lastRightValue = _select_at(game, lastRightPos);

            if (lastLeftPos - game.bets[lastLeftValue].dupes == 0) break;
            if (lastRightPos <= game.resPos) break;

            _val = _select_at(game, lastLeftPos - game.bets[lastLeftValue].dupes - 1);
            leftBetDif = game.res - lastLeftValue;
            rightBetDif = _val - game.res;

            if (gasused == 0) {
                gasused = gleft - gasleft() + 100000;
            }
            if (gasleft() < gasused) break;
        }

        game.lastRightValue = lastRightValue;
        game.lastRightPos = lastRightPos;
        game.lastLeftValue = lastLeftValue;
        game.lastLeftPos = lastLeftPos;
    }

    function _shiftLeftRight(Game storage game) internal returns (bool) {
        uint leftBetDif = game.res - game.lastLeftValue;
        uint rightBetDif = game.lastRightValue - game.res;
        if (rightBetDif == leftBetDif) return true;

        uint _val;


        if (leftBetDif > rightBetDif) {
            uint lastPos = _count(game) - 1;
            if (game.lastRightPos == lastPos) return true;
            if (game.lastLeftPos >= game.resPos) return true;
             
            _val = _select_at(game, game.lastRightPos + 1);
            rightBetDif = _val - game.res;

            _shiftRight(game, leftBetDif, rightBetDif, _val, lastPos);

        } else {
            if (game.lastLeftPos - game.bets[game.lastLeftValue].dupes == 0) return true;
            if (game.lastRightPos <= game.resPos) return true;
             
            _val = _select_at(game, game.lastLeftPos - game.bets[game.lastLeftValue].dupes - 1);
            leftBetDif = game.res - _val;

            _shiftLeft(game, leftBetDif, rightBetDif, _val);
        }

        return true;
    }


     
    function _setWinnersAmount(Game storage game, uint _start, uint _stop) internal {
        uint _bet;
        uint _betAmount;
        if (game.lastLeftPos == game.lastRightPos) {
            _bet = _select_at(game, game.lastLeftPos);
            game.winnersAmount = _getBetAmount(game, _bet);
            game.allDone = true;
        } else {
            _start = _start > 0 ? _start : game.lastLeftPos;
            _stop = _stop > 0 ? _stop : game.lastRightPos;
            uint i = _start;
            uint winnersAmount;
            while(i <= _stop) {
                if (i == game.resPos) {
                    i++;
                    continue;
                }
                _bet = _select_at(game, i);
                _betAmount = _getBetAmount(game, _bet);
                winnersAmount = winnersAmount.add(_betAmount);
                 
                if (i != _start && game.bets[_bet].dupes > 0) {
                    i += game.bets[_bet].dupes;
                }

                if (i >= game.lastRightPos) game.allDone = true;
                i++;
            }
             
            game.winnersAmount = winnersAmount;
        }

        if (game.allDone) {
            uint profit = game.amount - game.winnersAmount;
            if (profit > 0) {
                uint ownerPercent = profit.div(10);  
                game.prizePool = profit.sub(ownerPercent);
                dividendManagerAddress.transfer(ownerPercent);
            }
        }

    }

    function _getBetAmount(Game storage game, uint _bet) internal view returns (uint amount) {
        for (uint i = 0; i < game.users[_bet].length; i++) {
            amount = amount.add(game.betUsers[_bet][game.users[_bet][i]]);
        }
    }

    function _getPrize(Game storage game, address payable user) internal returns (uint amount) {
        require(game.allDone);
        require(!game.executed[user]);
        game.executed[user] = true;
        amount = _getPrizeAmount(game, user);

        require(amount > 0);
        user.transfer(amount);
        
    }

    function _getPrizeAmount(Game storage game, address user) internal view returns (uint amount){
        amount = _getUserAmount(game, user);
        if (amount > 0 && game.prizePool > 0) {
             
            amount = amount.add(game.prizePool.mul(amount).div(game.winnersAmount));
        }
    }

    function _getUserAmount(Game storage game, address user) internal view returns (uint amount){
        amount = 0;
        for (uint i = 0; i < game.userBets[user].length; i++) {
            if (game.userBets[user][i] >= game.lastLeftValue &&
                game.userBets[user][i] <= game.lastRightValue)
            {
                amount += game.betUsers[game.userBets[user][i]][user];
            }
        }
    }

     
     

    function getPos(uint _game, uint _value) public view returns (uint) {
        return _getPos(games[_game], _value);
    }

    function select_at(uint _game, uint pos) public view returns (uint) {
        return _select_at(games[_game], pos);
    }

    function count(uint _game) public view returns (uint) {
        return _count(games[_game]);
    }



     
     
    function _insert(Game storage game, uint _value) internal {
        if (_value==0)
            game.bets[_value].dupes++;
        else{
            insert_helper(game, 0, true, _value);
        }
    }

     
    function _getPos(Game storage game, uint _value) internal view returns (uint) {
        uint c = _count(game);
        if (c == 0) return 0;  
        if (game.bets[_value].count == 0) return 0;  

        uint _first = _select_at(game, 0);
        uint _last = _select_at(game, c-1);

         
        if (_value > _last || _value < _first) return 0;  
        if (_value == _first) return 0;
        if (_value == _last) return c - 1;

         
        uint min = 0;
        uint max = c-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            uint _val = _select_at(game, mid);
            if (_val <= _value) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return min;
    }


    function _select_at(Game storage game, uint pos) internal view returns (uint value){
        uint zeroes=game.bets[0].dupes;
         
        uint left_count;
        if (pos<zeroes) {
            return 0;
        }
        uint pos_new=pos-zeroes;
        uint cur=game.bets[0].children[true];
        Node storage cur_node=game.bets[cur];
        while(true){
            uint left=cur_node.children[false];
            uint cur_num=cur_node.dupes+1;
            if (left!=0) {

                left_count=game.bets[left].count;
            }
            else {
                left_count=0;
            }
            if (pos_new<left_count) {
                cur=left;
                cur_node=game.bets[left];
            }
            else if (pos_new<left_count+cur_num){
                return cur;
            }
            else {
                cur=cur_node.children[true];
                cur_node=game.bets[cur];
                pos_new-=left_count+cur_num;
            }
        }

    }


    function _count(Game storage game) internal view returns (uint){
        Node storage root=game.bets[0];
        Node storage child=game.bets[root.children[true]];
        return root.dupes+child.count;
    }


    function insert_helper(Game storage game, uint p_value, bool side, uint value) private {
        Node storage root=game.bets[p_value];
        uint c_value=root.children[side];
        if (c_value==0){
            root.children[side]=value;
            Node storage child=game.bets[value];
            child.parent=p_value;
            child.side=side;
            child.height=1;
            child.count=1;
            update_counts(game, value);
            rebalance_insert(game, value);
        }
        else if (c_value==value){
            game.bets[c_value].dupes++;
            update_count(game, value);
            update_counts(game, value);
        }
        else{
            bool side_new=(value >= c_value);
            insert_helper(game, c_value,side_new,value);
        }
    }


    function update_count(Game storage game, uint value) private {
        Node storage n=game.bets[value];
        n.count=1+game.bets[n.children[false]].count+game.bets[n.children[true]].count+n.dupes;
    }


    function update_counts(Game storage game, uint value) private {
        uint parent=game.bets[value].parent;
        while (parent!=0) {
            update_count(game, parent);
            parent=game.bets[parent].parent;
        }
    }


    function rebalance_insert(Game storage game, uint n_value) private {
        update_height(game, n_value);
        Node storage n=game.bets[n_value];
        uint p_value=n.parent;
        if (p_value!=0) {
            int p_bf=balance_factor(game, p_value);
            bool side=n.side;
            int sign;
            if (side)
                sign=-1;
            else
                sign=1;
            if (p_bf == sign*2) {
                if (balance_factor(game, n_value) == (-1 * sign))
                    rotate(game, n_value,side);
                rotate(game, p_value,!side);
            }
            else if (p_bf != 0)
                rebalance_insert(game, p_value);
        }
    }


    function update_height(Game storage game, uint value) private {
        Node storage n=game.bets[value];
        uint height_left=game.bets[n.children[false]].height;
        uint height_right=game.bets[n.children[true]].height;
        if (height_left>height_right)
            n.height=height_left+1;
        else
            n.height=height_right+1;
    }


    function balance_factor(Game storage game, uint value) private view returns (int bf) {
        Node storage n=game.bets[value];
        return int(game.bets[n.children[false]].height)-int(game.bets[n.children[true]].height);
    }


    function rotate(Game storage game, uint value,bool dir) private {
        bool other_dir=!dir;
        Node storage n=game.bets[value];
        bool side=n.side;
        uint parent=n.parent;
        uint value_new=n.children[other_dir];
        Node storage n_new=game.bets[value_new];
        uint orphan=n_new.children[dir];
        Node storage p=game.bets[parent];
        Node storage o=game.bets[orphan];
        p.children[side]=value_new;
        n_new.side=side;
        n_new.parent=parent;
        n_new.children[dir]=value;
        n.parent=value_new;
        n.side=dir;
        n.children[other_dir]=orphan;
        o.parent=value;
        o.side=other_dir;
        update_height(game, value);
        update_height(game, value_new);
        update_count(game, value);
        update_count(game, value_new);
    }

}