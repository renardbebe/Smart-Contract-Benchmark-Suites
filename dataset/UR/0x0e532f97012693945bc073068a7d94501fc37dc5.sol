 

contract GetsBurned {

    function () payable {
    }

    function BurnMe () {
         
        selfdestruct(address(this));
    }
}