echo "source $PWD/chipyard/scripts/fix-open-files.sh" > chipyard/env.sh
echo "__DIR=$PWD/chipyard" >> chipyard/env.sh
echo 'PATH=$__DIR/software/firemarshal:$PATH' >> chipyard/env.sh

