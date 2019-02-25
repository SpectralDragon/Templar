
echo 'Compile Templar'

swift build -c release -Xswiftc -static-stdlib

cd .build/release

echo 'Move Templar to system'
cp -f templar /usr/local/bin/templar
