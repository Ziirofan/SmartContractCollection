// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    
}

contract Bail is Owner {
    
    enum State { Created, Signed, Suspended, Release}
    
    address private locataire;
    address private proposal;
    uint256 private loyer;
    uint256 private echeance;
    uint256 private limitTime;
    
    mapping (uint256 => uint256) historical;
    
    State state;
    
    event ContractSuspended(address);

    constructor(uint256 echeance, uint256 limitTime) payable{
        echeance = echeance;
        limitTime = limitTime;
        state = State.Release;
    }

    /// Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// Fallback function is called when msg.data is not empty
    fallback() external payable {}
    
    function getEcheanceTime() public view returns (uint256){
        return echeance;
    } 
    
    function getlimitTime() public view returns (uint256){
        return limitTime;
    }
    
    function proposeBail(address to, uint256 loyer) public isOwner {
        require(state == State.Release, "Contract in use or propose");
        proposal = to;
        loyer = loyer;
        state = State.Created;
    }
    
    function signBail() external payable {
        require(msg.sender == proposal, "Sender not address proposal");
        if(msg.value == loyer){
            locataire = msg.Sender;
            state = State.Signed;
            Owner.transfer(msg.value);
        }
        else{
            revert("Not enough fund to sign contract");
        }
    }
    
    function pay(uint256 paytime, uint256 nextPayTime) external payable{
        require(state == State.Signed, "Bail not exist");
        require(msg.sender == locataire);
        historical[paytime] = msg.value;
        echeance = nextPayTime;
        Owner.transfer(msg.value);
    }
    
    function endBailPropose() external isOwner{
        state = State.Suspended;
        emit ContractSuspended(locataire);
        
    }
    
    
    

}
